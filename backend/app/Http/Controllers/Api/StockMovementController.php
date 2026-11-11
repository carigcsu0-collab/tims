<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class StockMovementController extends Controller
{
    public function index(Request $request)
    {
        $query = StockMovement::with(['item:id,name,sku', 'user:id,name']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('item_id')) {
            $query->where('item_id', $request->item_id);
        }

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function byItem(Request $request)
    {
        $request->validate(['item_id' => 'required|exists:items,id']);

        $movements = StockMovement::where('item_id', $request->item_id)
            ->with('user:id,name')
            ->latest()
            ->paginate($request->per_page ?? 15);

        return response()->json($movements);
    }
}
