<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\Request;

class ItemController extends Controller
{
    public function index(Request $request)
    {
        $query = Item::with(['category:id,name', 'supplier:id,name', 'qualification:id,name,code']);

        if ($request->boolean('low_stock_only', false)) {
            $query->whereColumn('quantity', '<=', 'minimum_stock');
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('qualification_id')) {
            $query->where('qualification_id', $request->qualification_id);
        }

        if ($request->has('condition')) {
            $query->where('condition', $request->condition);
        }

        if ($request->boolean('active_only', false)) {
            $query->where('is_active', true);
        }

        return response()->json($query->orderBy('name')->paginate(min((int) ($request->per_page ?? 15), 100)));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'sku' => 'required|string|unique:items,sku',
            'barcode' => 'nullable|string',
            'type' => 'required|in:tool,equipment,consumable,material,asset',
            'status' => 'nullable|in:in_stock,low_stock,out_of_stock,reserved,damaged,deprecated',
            'unit' => 'nullable|string',
            'category_id' => 'nullable|exists:categories,id',
            'qualification_id' => 'nullable|exists:qualifications,id',
            'condition' => 'nullable|in:working,needs_repair,condemned,missing',
            'description' => 'nullable|string',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'quantity' => 'nullable|integer|min:0',
            'minimum_stock' => 'nullable|integer|min:0',
            'maximum_stock' => 'nullable|integer|min:0',
            'reorder_level' => 'nullable|integer|min:0',
            'unit_cost' => 'nullable|numeric|min:0',
            'location' => 'nullable|string',
            'image_url' => 'nullable|string',
            'supplier_id' => 'nullable|exists:suppliers,id',
            'is_active' => 'boolean',
        ]);

        $data['total_value'] = ($data['quantity'] ?? 0) * ($data['unit_cost'] ?? 0);

        return response()->json(Item::create($data), 201);
    }

    public function show(Item $item)
    {
        return response()->json($item->load(['category', 'supplier', 'qualification', 'stockMovements.user:id,name']));
    }

    public function update(Request $request, Item $item)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'sku' => 'sometimes|string|unique:items,sku,' . $item->id,
            'barcode' => 'nullable|string',
            'type' => 'sometimes|in:tool,equipment,consumable,material,asset',
            'status' => 'nullable|in:in_stock,low_stock,out_of_stock,reserved,damaged,deprecated',
            'unit' => 'nullable|string',
            'category_id' => 'nullable|exists:categories,id',
            'qualification_id' => 'nullable|exists:qualifications,id',
            'condition' => 'nullable|in:working,needs_repair,condemned,missing',
            'description' => 'nullable|string',
            'brand' => 'nullable|string',
            'model' => 'nullable|string',
            'serial_number' => 'nullable|string',
            'quantity' => 'nullable|integer|min:0',
            'minimum_stock' => 'nullable|integer|min:0',
            'maximum_stock' => 'nullable|integer|min:0',
            'reorder_level' => 'nullable|integer|min:0',
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

    public function destroy(Item $item)
    {
        $item->delete();
        return response()->json(['message' => 'Item deleted successfully']);
    }

    public function lowStock()
    {
        $items = Item::whereColumn('quantity', '<=', 'minimum_stock')
            ->where('quantity', '>', 0)
            ->with(['category:id,name', 'supplier:id,name'])
            ->orderBy('quantity')
            ->paginate(15);

        return response()->json($items);
    }

    public function search(Request $request)
    {
        $request->validate(['q' => 'required|string|min:2']);

        $items = Item::where('name', 'like', '%' . $request->q . '%')
            ->orWhere('sku', 'like', '%' . $request->q . '%')
            ->orWhere('barcode', 'like', '%' . $request->q . '%')
            ->limit(20)
            ->get(['id', 'name', 'sku', 'type', 'status', 'quantity']);

        return response()->json($items);
    }
}
