<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Item;
use App\Models\PurchaseOrder;
use App\Models\Borrowing;
use App\Models\Maintenance;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function inventory(Request $request)
    {
        $query = Item::with(['category:id,name']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        $items = $query->orderBy('name')->get();

        return response()->json([
            'items' => $items,
            'summary' => [
                'total_items' => $items->count(),
                'total_quantity' => $items->sum('quantity'),
                'total_value' => $items->sum('total_value'),
                'low_stock' => $items->filter(fn ($i) => $i->quantity <= $i->minimum_stock && $i->quantity > 0)->count(),
                'out_of_stock' => $items->filter(fn ($i) => $i->quantity === 0)->count(),
            ],
        ]);
    }

    /** Master list of tools/equipment/consumables grouped by qualification. */
    public function inventorySummary(Request $request)
    {
        $query = Item::with('qualification:id,name,code')->orderBy('qualification_id')->orderBy('type')->orderBy('name');
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('qualification_id')) {
            $query->where('qualification_id', $request->qualification_id);
        }
        $items = $query->get();

        $rows = $items->map(fn ($i) => [
            $i->qualification?->code ?? 'Unassigned',
            $i->sku,
            $i->name,
            ucfirst($i->type),
            (string) $i->quantity,
            $i->unit ?? '',
            ucwords(str_replace('_', ' ', $i->condition ?? 'working')),
            $i->location ?? '',
        ])->values();

        return response()->json([
            'title' => 'Inventory Summary Report',
            'columns' => ['Qualification', 'SKU', 'Item', 'Type', 'Qty', 'Unit', 'Condition', 'Location'],
            'rows' => $rows,
            'summary' => [
                'Total items' => $items->count(),
                'Tools' => $items->where('type', 'tool')->count(),
                'Equipment' => $items->where('type', 'equipment')->count(),
                'Consumables/Materials' => $items->whereIn('type', ['consumable', 'material'])->count(),
            ],
        ]);
    }

    /** Items that are defective, missing, condemned or need repair. */
    public function condition(Request $request)
    {
        $query = Item::with('qualification:id,name,code')
            ->where(function ($q) {
                $q->whereIn('condition', ['needs_repair', 'condemned', 'missing'])
                  ->orWhere('status', 'damaged');
            })
            ->orderBy('condition')->orderBy('name');
        if ($request->filled('condition')) {
            $query->where('condition', $request->condition);
        }
        if ($request->filled('qualification_id')) {
            $query->where('qualification_id', $request->qualification_id);
        }
        $items = $query->get();

        $rows = $items->map(fn ($i) => [
            $i->qualification?->code ?? 'Unassigned',
            $i->sku,
            $i->name,
            ucfirst($i->type),
            (string) $i->quantity,
            ucwords(str_replace('_', ' ', $i->condition ?? 'working')),
            $i->location ?? '',
        ])->values();

        return response()->json([
            'title' => 'Item Condition Report (Defective / Missing / Needs Repair)',
            'columns' => ['Qualification', 'SKU', 'Item', 'Type', 'Qty', 'Condition', 'Location'],
            'rows' => $rows,
            'summary' => [
                'Needs repair' => $items->where('condition', 'needs_repair')->count(),
                'Condemned' => $items->where('condition', 'condemned')->count(),
                'Missing' => $items->where('condition', 'missing')->count(),
                'Total affected' => $items->count(),
            ],
        ]);
    }

    /** Items issued/consumed, including those issued to trainers/assessors. */
    public function issuance(Request $request)
    {
        $query = \App\Models\IssuanceItem::with([
            'item:id,name,sku,unit,qualification_id',
            'item.qualification:id,code',
            'issuance.issuedTo:id,name,position',
            'issuance.issuedBy:id,name',
        ])->whereHas('issuance', function ($q) use ($request) {
            if ($request->filled('date_from')) {
                $q->whereDate('issue_date', '>=', $request->date_from);
            }
            if ($request->filled('date_to')) {
                $q->whereDate('issue_date', '<=', $request->date_to);
            }
        });
        if ($request->filled('qualification_id')) {
            $query->whereHas('item', fn ($q) => $q->where('qualification_id', $request->qualification_id));
        }
        $lines = $query->get()->sortByDesc(fn ($l) => $l->issuance?->issue_date)->values();

        $rows = $lines->map(fn ($l) => [
            $l->issuance?->issue_date?->format('Y-m-d') ?? '',
            $l->issuance?->issuance_number ?? '',
            $l->issuance?->issuedTo?->name ?? '',
            $l->issuance?->issuedTo?->position ?? '',
            $l->item?->qualification?->code ?? 'Unassigned',
            $l->item?->name ?? '',
            (string) abs((int) $l->quantity),
            $l->item?->unit ?? '',
            $l->issuance?->purpose ?? '',
        ])->values();

        return response()->json([
            'title' => 'Stock-Out / Issuance Report',
            'columns' => ['Date', 'Issuance No.', 'Issued To', 'Position', 'Qualification', 'Item', 'Qty', 'Unit', 'Purpose'],
            'rows' => $rows,
            'summary' => [
                'Issuance lines' => $lines->count(),
                'Total quantity issued' => $lines->sum(fn ($l) => abs((int) $l->quantity)),
            ],
        ]);
    }

    public function procurement(Request $request)
    {
        $query = PurchaseOrder::with(['items.item:id,name,sku']);

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $orders = $query->latest()->get();

        return response()->json([
            'purchase_orders' => $orders,
            'summary' => [
                'total_orders' => $orders->count(),
                'total_amount' => $orders->sum('total_amount'),
                'received' => $orders->where('status', 'received')->count(),
                'pending' => $orders->whereIn('status', ['draft', 'sent', 'acknowledged', 'partial'])->count(),
            ],
        ]);
    }

    public function borrowing(Request $request)
    {
        $query = Borrowing::with(['item:id,name,sku', 'borrower:id,name']);

        if ($request->has('date_from')) {
            $query->whereDate('borrow_date', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('borrow_date', '<=', $request->date_to);
        }

        $borrowings = $query->latest()->get();

        return response()->json([
            'borrowings' => $borrowings,
            'summary' => [
                'total' => $borrowings->count(),
                'active' => $borrowings->where('status', 'borrowed')->count(),
                'returned' => $borrowings->where('status', 'returned')->count(),
                'overdue' => $borrowings->where('status', 'borrowed')->filter(fn ($b) => $b->is_overdue)->count(),
            ],
        ]);
    }

    public function maintenance(Request $request)
    {
        $query = Maintenance::with(['item:id,name,sku']);

        if ($request->has('date_from')) {
            $query->whereDate('scheduled_date', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('scheduled_date', '<=', $request->date_to);
        }

        $maintenances = $query->latest()->get();

        return response()->json([
            'maintenances' => $maintenances,
            'summary' => [
                'total' => $maintenances->count(),
                'scheduled' => $maintenances->where('status', 'scheduled')->count(),
                'completed' => $maintenances->where('status', 'completed')->count(),
                'total_cost' => $maintenances->sum('cost'),
            ],
        ]);
    }

    public function audit(Request $request)
    {
        $query = StockMovement::with(['item:id,name,sku', 'user:id,name']);

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $movements = $query->latest()->limit(500)->get();

        return response()->json([
            'movements' => $movements,
            'summary' => [
                'total_movements' => $movements->count(),
                'incoming' => $movements->whereIn('type', ['purchase', 'return_in'])->sum('quantity'),
                'outgoing' => abs($movements->whereIn('type', ['issuance', 'borrowing'])->sum('quantity')),
            ],
        ]);
    }

    public function stockMovement(Request $request)
    {
        $query = StockMovement::with(['item:id,name,sku', 'user:id,name']);

        if ($request->has('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->has('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('item_id')) {
            $query->where('item_id', $request->item_id);
        }

        $movements = $query->latest()->limit(500)->get();

        return response()->json([
            'movements' => $movements,
            'summary' => [
                'total_movements' => $movements->count(),
                'incoming' => $movements->whereIn('type', ['purchase', 'return_in'])->sum('quantity'),
                'outgoing' => abs($movements->whereIn('type', ['issuance', 'borrowing', 'return_out'])->sum('quantity')),
                'adjustments' => $movements->where('type', 'adjustment')->sum('quantity'),
            ],
        ]);
    }
}
