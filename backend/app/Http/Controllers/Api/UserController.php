<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->has('role')) {
            $query->where('role', $request->role);
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
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => 'nullable|string',
            'phone' => 'nullable|string',
            'position' => 'nullable|string',
            'department' => 'nullable|string',
            'center_name' => 'nullable|string',
            'is_active' => 'boolean',
            'permissions' => 'nullable|array',
        ]);

        return response()->json(User::create($data), 201);
    }

    public function show(User $user)
    {
        return response()->json($user);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:8',
            'role' => 'nullable|string',
            'phone' => 'nullable|string',
            'position' => 'nullable|string',
            'department' => 'nullable|string',
            'center_name' => 'nullable|string',
            'is_active' => 'boolean',
            'permissions' => 'nullable|array',
        ]);

        $user->update($data);
        return response()->json($user);
    }

    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['message' => 'User deleted successfully']);
    }
}
