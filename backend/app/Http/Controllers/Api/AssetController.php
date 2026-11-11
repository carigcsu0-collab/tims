<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\Request;

class AssetController extends Controller
{
    public function index(Request $request)
    {
        $query = Item::with(['category:id,name', 'supplier:id,name'])
            ->whereIn('type', ['asset', 'equipment']);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('serial_number', 'like', "%{$search}%");
            });
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->boolean('active_only', false)) {
            $query->where('is_active', true);
        }

        return response()->json($query->orderBy('name')->paginate($request->per_page ?? 15));
    }

    public function show($id)
    {
        $item = Item::whereIn('type', ['asset', 'equipment'])->findOrFail($id);
        return response()->json($item->load(['category', 'supplier', 'maintenances', 'stockMovements.user:id,name']));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'sku' => 'required|string|unique:items,sku',
            'barcode' => 'nullable|string',
            'type' => 'required|in:asset,equipment',
            'status' => 'nullable|in:in_stock,low_stock,out_of_stock,reserved,damaged,deprecated',
            'unit' => 'nullable|string',
            'category_id' => 'nullable|exists:categories,id',
            'description' => 'nullable|string',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'quantity' => 'nullable|integer|min:0',
            'unit_cost' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'image_url' => 'nullable|string',
            'supplier_id' => 'nullable|exists:suppliers,id',
            'is_active' => 'boolean',
        ]);

        $data['total_value'] = ($data['quantity'] ?? 0) * ($data['unit_cost'] ?? 0);

        return response()->json(Item::create($data), 201);
    }

    public function update(Request $request, $id)
    {
        $item = Item::whereIn('type', ['asset', 'equipment'])->findOrFail($id);

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'sku' => 'sometimes|string|unique:items,sku,' . $item->id,
            'barcode' => 'nullable|string',
            'type' => 'sometimes|in:asset,equipment',
            'status' => 'nullable|in:in_stock,low_stock,out_of_stock,reserved,damaged,deprecated',
            'unit' => 'nullable|string',
            'category_id' => 'nullable|exists:categories,id',
            'description' => 'nullable|string',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'quantity' => 'nullable|integer|min:0',
            'unit_cost' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'image_url' => 'nullable|string',
            'supplier_id' => 'nullable|exists:suppliers,id',
            'is_active' => 'boolean',
        ]);

        if (isset($data['quantity']) || isset($data['unit_cost'])) {
            $data['total_value'] = ($data['quantity'] ?? $item->quantity) * ($data['unit_cost'] ?? $item->unit_cost);
        }

        $item->update($data);
        return response()->json($item);
    }

    public function destroy($id)
    {
        $item = Item::whereIn('type', ['asset', 'equipment'])->findOrFail($id);
        $item->delete();
        return response()->json(['message' => 'Asset deleted successfully']);
    }
}
