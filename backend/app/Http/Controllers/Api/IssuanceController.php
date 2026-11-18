<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Issuance;
use App\Models\Item;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class IssuanceController extends Controller
{
    public function index(Request $request)
    {
        $query = Issuance::with(['issuedTo:id,name', 'issuedBy:id,name', 'items.item:id,name,sku']);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('issuance_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'issuance_number' => 'required|string|unique:issuances,issuance_number',
            'issued_to' => 'required|exists:users,id',
            'issue_date' => 'required|date',
            'purpose' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|exists:items,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.notes' => 'nullable|string',
        ]);

        $items = $data['items'];
        unset($data['items']);
        $data['issued_by'] = $request->user()->id;

        $issuance = DB::transaction(function () use ($data, $items, $request) {
            $issuance = Issuance::create($data);

            foreach ($items as $item) {
                $issuance->items()->create($item);

                $invItem = Item::lockForUpdate()->find($item['item_id']);
                $newQty = $invItem->quantity - $item['quantity'];

                if ($newQty < 0) {
                    throw ValidationException::withMessages([
                        'items' => ["Insufficient stock for item: {$invItem->name}"],
                    ]);
                }

                $invItem->update([
                    'quantity' => $newQty,
                    'total_value' => $newQty * $invItem->unit_cost,
                ]);

                StockMovement::create([
                    'item_id' => $invItem->id,
                    'type' => 'issuance',
                    'quantity' => -$item['quantity'],
                    'balance_after' => $newQty,
                    'user_id' => $request->user()->id,
                    'reference' => 'issuance',
                    'reference_id' => $issuance->id,
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            return $issuance;
        });

        return response()->json($issuance->load('items.item'), 201);
    }

    public function show(Issuance $issuance)
    {
        return response()->json($issuance->load(['issuedTo', 'issuedBy', 'items.item']));
    }

    public function update(Request $request, Issuance $issuance)
    {
        $data = $request->validate([
            'purpose' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $issuance->update($data);
        return response()->json($issuance);
    }

    public function destroy(Request $request, Issuance $issuance)
    {
        DB::transaction(function () use ($issuance, $request) {
            foreach ($issuance->items as $line) {
                $invItem = Item::lockForUpdate()->find($line->item_id);
                if (! $invItem) {
                    continue;
                }

                $newQty = $invItem->quantity + $line->quantity;
                $invItem->update([
                    'quantity' => $newQty,
                    'total_value' => $newQty * $invItem->unit_cost,
                ]);

                StockMovement::create([
                    'item_id' => $invItem->id,
                    'type' => 'return_in',
                    'quantity' => $line->quantity,
                    'balance_after' => $newQty,
                    'user_id' => $request->user()->id,
                    'reference' => 'issuance_deleted',
                    'reference_id' => $issuance->id,
                    'notes' => "Stock restored: issuance {$issuance->issuance_number} deleted",
                ]);
            }

            $issuance->items()->delete();
            $issuance->delete();
        });

        return response()->json(['message' => 'Issuance deleted successfully']);
    }
}
