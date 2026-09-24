<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Chofer;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class ChoferController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $choferes = Chofer::with('user:id,name,email,username')->get();
        return response()->json($choferes);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users',
            'email' => 'nullable|email|max:255|unique:users',
            'numero_licencia' => 'nullable|string|max:255',
            'tipo_licencia' => 'nullable|string|max:255',
            'estado' => 'required|in:activo,inactivo,vacaciones',
        ]);

        try {
            DB::beginTransaction();

            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => Hash::make('12345678'), // Default password
            ]);

            $chofer = Chofer::create([
                'user_id' => $user->id,
                'numero_licencia' => $request->numero_licencia,
                'tipo_licencia' => $request->tipo_licencia,
                'estado' => $request->estado,
            ]);

            DB::commit();

            return response()->json($chofer->load('user'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al crear chofer', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $chofer = Chofer::with('user')->findOrFail($id);
        return response()->json($chofer);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $chofer = Chofer::with('user')->findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users,username,' . $chofer->user_id,
            'email' => 'nullable|email|max:255|unique:users,email,' . $chofer->user_id,
            'numero_licencia' => 'nullable|string|max:255',
            'tipo_licencia' => 'nullable|string|max:255',
            'estado' => 'required|in:activo,inactivo,vacaciones',
        ]);

        try {
            DB::beginTransaction();

            $chofer->user->update([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
            ]);

            $chofer->update([
                'numero_licencia' => $request->numero_licencia,
                'tipo_licencia' => $request->tipo_licencia,
                'estado' => $request->estado,
            ]);

            DB::commit();

            return response()->json($chofer->fresh('user'));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al actualizar chofer', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $chofer = Chofer::findOrFail($id);
        try {
            DB::beginTransaction();
            // Optional: delete user as well if chofer is deleted, or just delete chofer.
            // Depending on business logic, we might just soft delete or delete the chofer profile.
            // Let's delete the chofer profile.
            $chofer->delete();
            DB::commit();
            return response()->json(['message' => 'Chofer eliminado correctamente.']);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al eliminar chofer', 'error' => $e->getMessage()], 500);
        }
    }
}
