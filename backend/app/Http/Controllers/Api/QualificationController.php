<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Qualification;
use Illuminate\Http\Request;

class QualificationController extends Controller
{
    public function index(Request $request)
    {
        $query = Qualification::withCount('items');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(fn ($q) => $q->where('name', 'like', "%{$search}%")->orWhere('code', 'like', "%{$search}%"));
        }

        if ($request->boolean('active_only', false)) {
            $query->where('is_active', true);
        }

        return response()->json($query->orderBy('name')->paginate(min((int) ($request->per_page ?? 50), 200)));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:qualifications,code',
            'nc_level' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        return response()->json(Qualification::create($data), 201);
    }

    public function show(Qualification $qualification)
    {
        return response()->json($qualification->loadCount('items'));
    }

    public function update(Request $request, Qualification $qualification)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'code' => 'sometimes|string|max:50|unique:qualifications,code,' . $qualification->id,
            'nc_level' => 'nullable|string|max:50',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $qualification->update($data);
        return response()->json($qualification);
    }

    public function destroy(Qualification $qualification)
    {
        $qualification->delete();
        return response()->json(['message' => 'Qualification deleted successfully']);
    }
}
