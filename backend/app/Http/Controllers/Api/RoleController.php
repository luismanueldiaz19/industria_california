<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Spatie\Permission\Models\Role;

class RoleController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $roles = Role::all();
        // Add users_count manually
        foreach ($roles as $role) {
            $role->users_count = \Illuminate\Support\Facades\DB::table('model_has_roles')
                                    ->where('role_id', $role->id)
                                    ->count();
        }
        return response()->json($roles);
    }

    public function store(Request $request) {
        $request->validate([
            'name' => 'required|string|max:255|unique:roles,name',
            'description' => 'nullable|string|max:255',
        ]);

        $role = Role::create([
            'name' => $request->name,
            'description' => $request->description,
            'guard_name' => 'web'
        ]);

        return response()->json($role, 201);
    }

    public function show(string $id)
    {
        $role = Role::findOrFail($id);
        $role->users_count = \Illuminate\Support\Facades\DB::table('model_has_roles')
                                ->where('role_id', $role->id)
                                ->count();
        return response()->json($role);
    }

    public function update(Request $request, string $id)
    {
        $role = Role::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255|unique:roles,name,' . $role->id,
            'description' => 'nullable|string|max:255',
        ]);

        $role->update([
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return response()->json($role);
    }

    public function destroy(string $id)
    {
        $role = Role::findOrFail($id);
        
        if ($role->name === 'admin') {
            return response()->json(['message' => 'No se puede eliminar el rol admin'], 403);
        }

        $role->delete();
        return response()->json(['message' => 'Rol eliminado correctamente']);
    }
}
