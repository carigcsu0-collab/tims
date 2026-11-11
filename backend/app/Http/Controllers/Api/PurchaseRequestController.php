<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PurchaseRequest;
use Illuminate\Http\Request;

class PurchaseRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = PurchaseRequest::with(['requestedBy:id,name', 'approvedBy:id,name', 'items.item:id,name,sku']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('pr_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'pr_number' => 'required|string|unique:purchase_requests,pr_number',
            'requested_by' => 'required|exists:users,id',
            'purpose' => 'nullable|string',
            'department' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|exists:items,id',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_cost' => 'required|numeric|min:0',
            'items.*.unit' => 'nullable|string',
            'items.*.notes' => 'nullable|string',
        ]);

        $items = $data['items'];
        unset($data['items']);

        $total = collect($items)->sum(fn ($item) => $item['quantity'] * $item['unit_cost']);
        $data['total_amount'] = $total;
        $data['status'] = 'pending';

        $pr = PurchaseRequest::create($data);
        foreach ($items as $item) {
            $pr->items()->create($item);
        }

        return response()->json($pr->load('items.item'), 201);
    }

    public function show(PurchaseRequest $purchaseRequest)
    {
        return response()->json($purchaseRequest->load(['requestedBy', 'approvedBy', 'items.item']));
    }

    public function update(Request $request, PurchaseRequest $purchaseRequest)
    {
        $data = $request->validate([
            'purpose' => 'nullable|string',
            'department' => 'nullable|string',
        ]);

        $purchaseRequest->update($data);
        return response()->json($purchaseRequest->load('items.item'));
    }

    public function destroy(PurchaseRequest $purchaseRequest)
    {
        $purchaseRequest->delete();
        return response()->json(['message' => 'Purchase request deleted successfully']);
    }

    public function approve(Request $request, $id)
    {
        $pr = PurchaseRequest::findOrFail($id);

        if ($pr->status !== 'pending') {
            return response()->json(['message' => 'Only pending requests can be approved'], 422);
        }

        $pr->update([
            'status' => 'approved',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
        ]);

        return response()->json($pr->load('items.item'));
    }

    public function reject(Request $request, $id)
    {
        $request->validate(['rejected_reason' => 'required|string']);

        $pr = PurchaseRequest::findOrFail($id);

        if (!in_array($pr->status, ['pending', 'draft'])) {
            return response()->json(['message' => 'Only pending or draft requests can be rejected'], 422);
        }

        $pr->update([
            'status' => 'rejected',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
            'rejected_reason' => $request->rejected_reason,
        ]);

        return response()->json($pr);
    }
}
