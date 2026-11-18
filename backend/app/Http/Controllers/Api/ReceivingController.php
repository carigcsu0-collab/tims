<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Receiving;
use App\Models\Item;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ReceivingController extends Controller
{
    public function index(Request $request)
    {
        $query = Receiving::with(['receivedBy:id,name', 'purchaseOrder:id,po_number', 'items.item:id,name,sku']);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('receiving_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'receiving_number' => 'required|string|unique:receivings,receiving_number',
            'purchase_order_id' => 'nullable|exists:purchase_orders,id',
            'received_date' => 'required|date',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|exists:items,id',
            'items.*.quantity_received' => 'required|integer|min:1',
            'items.*.unit_cost' => 'nullable|numeric|min:0',
            'items.*.notes' => 'nullable|string',
        ]);

        $items = $data['items'];
        unset($data['items']);
        $data['received_by'] = $request->user()->id;

        $receiving = DB::transaction(function () use ($data, $items, $request) {
            $receiving = Receiving::create($data);

            foreach ($items as $item) {
                $receiving->items()->create($item);

                $invItem = Item::find($item['item_id']);
                $newQty = $invItem->quantity + $item['quantity_received'];
                $invItem->update([
                    'quantity' => $newQty,
                    'total_value' => $newQty * $invItem->unit_cost,
                ]);

                StockMovement::create([
                    'item_id' => $invItem->id,
                    'type' => 'purchase',
                    'quantity' => $item['quantity_received'],
                    'balance_after' => $newQty,
                    'user_id' => $request->user()->id,
                    'reference' => 'receiving',
                    'reference_id' => $receiving->id,
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            return $receiving;
        });

        return response()->json($receiving->load('items.item'), 201);
    }

    public function show(Receiving $receiving)
    {
        return response()->json($receiving->load(['receivedBy', 'purchaseOrder', 'items.item']));
    }

    public function update(Request $request, Receiving $receiving)
    {
        $data = $request->validate([
            'notes' => 'nullable|string',
        ]);

        $receiving->update($data);
        return response()->json($receiving);
    }

    public function destroy(Request $request, Receiving $receiving)
    {
        DB::transaction(function () use ($receiving, $request) {
            foreach ($receiving->items as $line) {
                $invItem = Item::lockForUpdate()->find($line->item_id);
                if (! $invItem) {
                    continue;
                }

                $newQty = $invItem->quantity - $line->quantity_received;
                if ($newQty < 0) {
                    throw ValidationException::withMessages([
                        'items' => ["Cannot delete: stock for {$invItem->name} has already been issued"],
                    ]);
                }

                $invItem->update([
                    'quantity' => $newQty,
                    'total_value' => $newQty * $invItem->unit_cost,
                ]);

                StockMovement::create([
                    'item_id' => $invItem->id,
                    'type' => 'adjustment',
                    'quantity' => -$line->quantity_received,
                    'balance_after' => $newQty,
                    'user_id' => $request->user()->id,
                    'reference' => 'receiving_deleted',
                    'reference_id' => $receiving->id,
                    'notes' => "Stock reversed: receiving {$receiving->receiving_number} deleted",
                ]);
            }

            $receiving->items()->delete();
            $receiving->delete();
        });

        return response()->json(['message' => 'Receiving deleted successfully']);
    }
}
