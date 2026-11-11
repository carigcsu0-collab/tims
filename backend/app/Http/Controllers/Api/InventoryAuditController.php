<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryAudit;
use Illuminate\Http\Request;

class InventoryAuditController extends Controller
{
    public function index(Request $request)
    {
        $query = InventoryAudit::with(['auditor:id,name', 'items.item:id,name,sku']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('audit_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'audit_number' => 'required|string|unique:inventory_audits,audit_number',
            'audited_by' => 'required|exists:users,id',
            'scheduled_date' => 'required|date',
            'notes' => 'nullable|string',
            'items' => 'nullable|array',
            'items.*.item_id' => 'required_with:items|exists:items,id',
            'items.*.system_quantity' => 'required_with:items|integer|min:0',
        ]);

        $items = $data['items'] ?? [];
        unset($data['items']);
        $data['status'] = 'scheduled';

        $audit = InventoryAudit::create($data);
        foreach ($items as $item) {
            $audit->items()->create($item);
        }

        return response()->json($audit->load('items.item'), 201);
    }

    public function show(InventoryAudit $inventoryAudit)
    {
        return response()->json($inventoryAudit->load(['auditor', 'items.item']));
    }

    public function update(Request $request, InventoryAudit $inventoryAudit)
    {
        $data = $request->validate([
            'status' => 'nullable|in:scheduled,in_progress,completed,cancelled',
            'notes' => 'nullable|string',
            'started_at' => 'nullable|date',
            'completed_at' => 'nullable|date',
        ]);

        $inventoryAudit->update($data);
        return response()->json($inventoryAudit->load('items.item'));
    }

    public function destroy(InventoryAudit $inventoryAudit)
    {
        $inventoryAudit->delete();
        return response()->json(['message' => 'Inventory audit deleted successfully']);
    }

    public function complete(Request $request, $id)
    {
        $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:inventory_audit_items,id',
            'items.*.counted_quantity' => 'required|integer|min:0',
            'items.*.discrepancy' => 'nullable|string',
        ]);

        $audit = InventoryAudit::findOrFail($id);

        if (!in_array($audit->status, ['scheduled', 'in_progress'])) {
            return response()->json(['message' => 'Only scheduled or in-progress audits can be completed'], 422);
        }

        foreach ($request->items as $itemData) {
            $auditItem = $audit->items()->find($itemData['id']);
            if ($auditItem) {
                $auditItem->update([
                    'counted_quantity' => $itemData['counted_quantity'],
                    'discrepancy' => $itemData['discrepancy'] ?? null,
                ]);
            }
        }

        $audit->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json($audit->load('items.item'));
    }
}
