<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use Illuminate\Http\Request;

class PurchaseOrderController extends Controller
{
    public function index(Request $request)
    {
        $query = PurchaseOrder::with(['createdBy:id,name', 'items.item:id,name,sku']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('po_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'po_number' => 'required|string|unique:purchase_orders,po_number',
            'purchase_request_id' => 'nullable|exists:purchase_requests,id',
            'expected_delivery_date' => 'nullable|date',
            'payment_terms' => 'nullable|string',
            'delivery_address' => 'nullable|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|exists:items,id',
            'items.*.quantity_ordered' => 'required|integer|min:1',
            'items.*.unit_cost' => 'required|numeric|min:0',
            'items.*.unit' => 'nullable|string',
            'items.*.notes' => 'nullable|string',
        ]);

        $items = $data['items'];
        unset($data['items']);

        $total = collect($items)->sum(fn ($item) => $item['quantity_ordered'] * $item['unit_cost']);
        $data['total_amount'] = $total;
        $data['status'] = 'draft';
        $data['created_by'] = $request->user()->id;

        $po = PurchaseOrder::create($data);
        foreach ($items as $item) {
            $po->items()->create($item);
        }

        return response()->json($po->load('items.item'), 201);
    }

    public function show(PurchaseOrder $purchaseOrder)
    {
        return response()->json($purchaseOrder->load(['createdBy', 'items.item']));
    }

    public function update(Request $request, PurchaseOrder $purchaseOrder)
    {
        $data = $request->validate([
            'status' => 'nullable|in:draft,sent,acknowledged,partial,received,cancelled',
            'expected_delivery_date' => 'nullable|date',
            'actual_delivery_date' => 'nullable|date',
            'payment_terms' => 'nullable|string',
            'delivery_address' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $purchaseOrder->update($data);
        return response()->json($purchaseOrder->load('items.item'));
    }

    public function destroy(PurchaseOrder $purchaseOrder)
    {
        $purchaseOrder->delete();
        return response()->json(['message' => 'Purchase order deleted successfully']);
    }
}
