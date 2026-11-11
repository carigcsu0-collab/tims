<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Borrowing;
use App\Models\Item;
use App\Models\ReturnModel;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BorrowingController extends Controller
{
    public function index(Request $request)
    {
        $query = Borrowing::with(['item:id,name,sku', 'borrower:id,name', 'approvedBy:id,name']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('borrow_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'borrow_number' => 'required|string|unique:borrowings,borrow_number',
            'item_id' => 'required|exists:items,id',
            'borrower_id' => 'required|exists:users,id',
            'borrow_date' => 'required|date',
            'expected_return_date' => 'nullable|date|after:borrow_date',
            'quantity' => 'nullable|integer|min:1',
            'purpose' => 'nullable|string',
            'condition_out' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $data['status'] = 'requested';
        $data['quantity'] = $data['quantity'] ?? 1;

        $borrowing = Borrowing::create($data);
        return response()->json($borrowing->load(['item', 'borrower']), 201);
    }

    public function show(Borrowing $borrowing)
    {
        return response()->json($borrowing->load(['item', 'borrower', 'approvedBy']));
    }

    public function update(Request $request, Borrowing $borrowing)
    {
        $data = $request->validate([
            'expected_return_date' => 'nullable|date|after_or_equal:' . $borrowing->borrow_date->format('Y-m-d'),
            'purpose' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $borrowing->update($data);
        return response()->json($borrowing);
    }

    public function destroy(Borrowing $borrowing)
    {
        $borrowing->delete();
        return response()->json(['message' => 'Borrowing deleted successfully']);
    }

    public function approve(Request $request, $id)
    {
        $borrowing = Borrowing::findOrFail($id);

        if ($borrowing->status !== 'requested') {
            return response()->json(['message' => 'Only requested borrowings can be approved'], 422);
        }

        $error = DB::transaction(function () use ($request, $borrowing) {
            $item = Item::lockForUpdate()->find($borrowing->item_id);
            $newQty = $item->quantity - $borrowing->quantity;

            if ($newQty < 0) {
                return "Insufficient stock for item: {$item->name}";
            }

            $borrowing->update([
                'status' => 'borrowed',
                'approved_by' => $request->user()->id,
            ]);

            $item->update([
                'quantity' => $newQty,
                'total_value' => $newQty * $item->unit_cost,
            ]);

            StockMovement::create([
                'item_id' => $item->id,
                'type' => 'borrowing',
                'quantity' => -$borrowing->quantity,
                'balance_after' => $newQty,
                'user_id' => $request->user()->id,
                'reference' => 'borrowing',
                'reference_id' => $borrowing->id,
            ]);

            return null;
        });

        if ($error) {
            return response()->json(['message' => $error], 422);
        }

        return response()->json($borrowing->load(['item', 'borrower', 'approvedBy']));
    }

    public function reject(Request $request, $id)
    {
        $borrowing = Borrowing::findOrFail($id);

        if ($borrowing->status !== 'requested') {
            return response()->json(['message' => 'Only requested borrowings can be rejected'], 422);
        }

        $borrowing->update([
            'status' => 'rejected',
            'approved_by' => $request->user()->id,
        ]);

        return response()->json($borrowing);
    }

    public function returnItem(Request $request, $id)
    {
        $request->validate([
            'condition' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $borrowing = Borrowing::findOrFail($id);

        if ($borrowing->status !== 'borrowed') {
            return response()->json(['message' => 'Only borrowed items can be returned'], 422);
        }

        $return = DB::transaction(function () use ($request, $borrowing) {
            $return = ReturnModel::create([
                'return_number' => 'RET-' . date('Ymd') . '-' . str_pad($borrowing->id, 4, '0', STR_PAD_LEFT),
                'borrowing_id' => $borrowing->id,
                'item_id' => $borrowing->item_id,
                'returned_by' => $borrowing->borrower_id,
                'return_date' => now(),
                'quantity' => $borrowing->quantity,
                'condition' => $request->condition,
                'notes' => $request->notes,
            ]);

            $borrowing->update([
                'status' => 'returned',
                'actual_return_date' => now(),
                'condition_in' => $request->condition,
                'return_id' => $return->id,
            ]);

            $item = Item::lockForUpdate()->find($borrowing->item_id);
            $newQty = $item->quantity + $borrowing->quantity;
            $item->update([
                'quantity' => $newQty,
                'total_value' => $newQty * $item->unit_cost,
            ]);

            StockMovement::create([
                'item_id' => $item->id,
                'type' => 'return_in',
                'quantity' => $borrowing->quantity,
                'balance_after' => $newQty,
                'user_id' => $request->user()->id,
                'reference' => 'return',
                'reference_id' => $return->id,
            ]);

            return $return;
        });

        return response()->json($return->load(['borrowing', 'item']));
    }
}
