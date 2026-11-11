<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\Supplier;
use App\Models\PurchaseRequest;
use App\Models\Borrowing;
use App\Models\Maintenance;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function stats()
    {
        $lowStockConsumables = Item::whereIn('type', ['consumable', 'material'])
            ->where('is_active', true)
            ->whereColumn('quantity', '<=', 'minimum_stock')
            ->with('qualification:id,name,code')
            ->orderByRaw('quantity - minimum_stock')
            ->limit(20)
            ->get(['id', 'name', 'sku', 'unit', 'quantity', 'minimum_stock', 'qualification_id']);

        return response()->json([
            'total_items' => Item::count(),
            'total_tools' => Item::where('type', 'tool')->count(),
            'total_equipment' => Item::where('type', 'equipment')->count(),
            'total_consumables' => Item::whereIn('type', ['consumable', 'material'])->count(),
            'low_stock_count' => Item::whereColumn('quantity', '<=', 'minimum_stock')->where('quantity', '>', 0)->count(),
            'out_of_stock_count' => Item::where('quantity', 0)->count(),
            'total_inventory_value' => Item::sum('total_value'),
            'needs_repair_count' => Item::where('condition', 'needs_repair')->count(),
            'condemned_count' => Item::where('condition', 'condemned')->count(),
            'missing_count' => Item::where('condition', 'missing')->count(),
            'low_stock_consumables' => $lowStockConsumables,
            'pending_purchase_requests' => PurchaseRequest::where('status', 'pending')->count(),
            'active_borrowings' => Borrowing::where('status', 'borrowed')->count(),
            'pending_maintenance' => Maintenance::where('status', 'scheduled')->count(),
            'total_suppliers' => Supplier::count(),
        ]);
    }

    public function charts()
    {
        $itemsByType = Item::selectRaw('type, COUNT(*) as count')->groupBy('type')->pluck('count', 'type');
        $itemsByStatus = Item::selectRaw('status, COUNT(*) as count')->groupBy('status')->pluck('count', 'status');
        $stockMovementsByType = StockMovement::selectRaw('type, COUNT(*) as count')
            ->whereMonth('created_at', now()->month)
            ->groupBy('type')->pluck('count', 'type');

        return response()->json([
            'items_by_type' => $itemsByType,
            'items_by_status' => $itemsByStatus,
            'stock_movements_by_type' => $stockMovementsByType,
        ]);
    }

    public function recentActivity()
    {
        $movements = StockMovement::with(['item:id,name,sku', 'user:id,name'])
            ->latest()->limit(10)->get();

        return response()->json($movements);
    }
}
