<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Maintenance;
use Illuminate\Http\Request;

class MaintenanceController extends Controller
{
    public function index(Request $request)
    {
        $query = Maintenance::with(['item:id,name,sku']);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where('maintenance_number', 'like', "%{$search}%");
        }

        return response()->json($query->latest()->paginate($request->per_page ?? 15));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'maintenance_number' => 'required|string|unique:maintenances,maintenance_number',
            'item_id' => 'required|exists:items,id',
            'type' => 'required|in:preventive,corrective,calibration,inspection,repair',
            'scheduled_date' => 'required|date',
            'technician' => 'nullable|string',
            'cost' => 'nullable|numeric|min:0',
            'description' => 'nullable|string',
        ]);

        $data['status'] = 'scheduled';

        return response()->json(Maintenance::create($data), 201);
    }

    public function show(Maintenance $maintenance)
    {
        return response()->json($maintenance->load('item'));
    }

    public function update(Request $request, Maintenance $maintenance)
    {
        $data = $request->validate([
            'type' => 'sometimes|in:preventive,corrective,calibration,inspection,repair',
            'status' => 'nullable|in:scheduled,in_progress,completed,cancelled,overdue',
            'scheduled_date' => 'sometimes|date',
            'technician' => 'nullable|string',
            'cost' => 'nullable|numeric|min:0',
            'description' => 'nullable|string',
            'findings' => 'nullable|string',
            'recommendations' => 'nullable|string',
            'next_maintenance_date' => 'nullable|date',
        ]);

        $maintenance->update($data);
        return response()->json($maintenance);
    }

    public function destroy(Maintenance $maintenance)
    {
        $maintenance->delete();
        return response()->json(['message' => 'Maintenance deleted successfully']);
    }

    public function complete(Request $request, $id)
    {
        $request->validate([
            'findings' => 'nullable|string',
            'recommendations' => 'nullable|string',
            'cost' => 'nullable|numeric|min:0',
            'next_maintenance_date' => 'nullable|date',
        ]);

        $maintenance = Maintenance::findOrFail($id);

        if (!in_array($maintenance->status, ['scheduled', 'in_progress'])) {
            return response()->json(['message' => 'Only scheduled or in-progress maintenance can be completed'], 422);
        }

        $maintenance->update([
            'status' => 'completed',
            'completed_date' => now(),
            'findings' => $request->findings,
            'recommendations' => $request->recommendations,
            'cost' => $request->cost ?? $maintenance->cost,
            'next_maintenance_date' => $request->next_maintenance_date,
        ]);

        return response()->json($maintenance->load('item'));
    }
}
