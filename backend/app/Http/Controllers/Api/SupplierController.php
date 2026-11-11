<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Supplier;
use Illuminate\Http\Request;

class SupplierController extends Controller
{
    public function index(Request $request)
    {
        $query = Supplier::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('code', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%");
            });
        }

        if ($request->boolean('active_only', false)) {
            $query->where('is_active', true);
        }

        return response()->json($query->orderBy('name')->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|unique:suppliers,code',
            'contact_person' => 'nullable|string',
            'email' => 'nullable|email',
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string',
            'province' => 'nullable|string',
            'zip_code' => 'nullable|string',
            'tin' => 'nullable|string',
            'website' => 'nullable|string',
            'notes' => 'nullable|string',
            'is_active' => 'boolean',
            'rating' => 'nullable|numeric|min:0|max:5',
        ]);

        return response()->json(Supplier::create($data), 201);
    }

    public function show(Supplier $supplier)
    {
        return response()->json($supplier->load('items:id,name,sku,supplier_id', 'purchaseOrders:id,po_number,status,supplier_id'));
    }

    public function update(Request $request, Supplier $supplier)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'nullable|string|unique:suppliers,code,' . $supplier->id,
            'contact_person' => 'nullable|string',
            'email' => 'nullable|email',
            'phone' => 'nullable|string',
            'address' => 'nullable|string',
            'city' => 'nullable|string',
            'province' => 'nullable|string',
            'zip_code' => 'nullable|string',
            'tin' => 'nullable|string',
            'website' => 'nullable|string',
            'notes' => 'nullable|string',
            'is_active' => 'boolean',
            'rating' => 'nullable|numeric|min:0|max:5',
        ]);

        $supplier->update($data);
        return response()->json($supplier);
    }

    public function destroy(Supplier $supplier)
    {
        $supplier->delete();
        return response()->json(['message' => 'Supplier deleted successfully']);
    }
}
