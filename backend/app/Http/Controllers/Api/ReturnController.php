<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReturnModel;
use Illuminate\Http\Request;

class ReturnController extends Controller
{
    public function index(Request $request)
    {
        $query = ReturnModel::with(['item:id,name,sku', 'returnedBy:id,name', 'borrowing:id,borrow_number']);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('return_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'return_number' => 'required|string|unique:returns,return_number',
            'borrowing_id' => 'nullable|exists:borrowings,id',
            'item_id' => 'required|exists:items,id',
            'returned_by' => 'required|exists:users,id',
            'return_date' => 'required|date',
            'quantity' => 'nullable|integer|min:1',
            'condition' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        return response()->json(ReturnModel::create($data), 201);
    }

    public function show(ReturnModel $return)
    {
        return response()->json($return->load(['item', 'returnedBy', 'borrowing']));
    }

    public function update(Request $request, ReturnModel $return)
    {
        $data = $request->validate([
            'condition' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $return->update($data);
        return response()->json($return);
    }

    public function destroy(ReturnModel $return)
    {
        $return->delete();
        return response()->json(['message' => 'Return deleted successfully']);
    }
}
