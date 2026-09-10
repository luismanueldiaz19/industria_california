<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Registrar un nuevo usuario.
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users',
            'password' => 'required|string',
            'role' => 'nullable|string|exists:roles,name',
        ]);

        $user = User::create([
            'name' => $request->name,
            'username' => $request->username,
            'password' => Hash::make($request->password),
        ]);

        if ($request->filled('role')) {
            $user->assignRole($request->role);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado exitosamente',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'profile_photo_url' => $user->profile_photo_path ? url('storage/' . $user->profile_photo_path) : null,
                'roles' => $user->getRoleNames(),
            ]
        ], 201);
    }

    /**
     * Iniciar sesión y obtener un token personal de acceso.
     */
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', $request->username)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Las credenciales proporcionadas son incorrectas.'
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'profile_photo_url' => $user->profile_photo_path ? url('storage/' . $user->profile_photo_path) : null,
                'roles' => $user->getRoleNames(),
            ]
        ], 200);
    }

    /**
     * Cerrar sesión (revocar el token actual).
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada con éxito.'
        ], 200);
    }

    /**
     * Actualizar perfil del usuario (nombre, foto, contraseña).
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'current_password' => 'required_with:new_password|string',
            'new_password' => 'nullable|string|min:6',
            'profile_photo' => 'nullable|image|max:5120',
        ]);

        if ($request->has('name')) {
            $user->name = $request->name;
        }

        if ($request->filled('new_password')) {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json(['error' => 'La contraseña actual es incorrecta.'], 403);
            }
            $user->password = Hash::make($request->new_password);
        }

        if ($request->hasFile('profile_photo')) {
            // Eliminar foto anterior si existe
            if ($user->profile_photo_path && \Illuminate\Support\Facades\Storage::disk('public')->exists($user->profile_photo_path)) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($user->profile_photo_path);
            }
            $path = $request->file('profile_photo')->store('profile-photos', 'public');
            $user->profile_photo_path = $path;
        }

        $user->save();

        return response()->json([
            'message' => 'Perfil actualizado correctamente.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->username,
                'profile_photo_url' => $user->profile_photo_path ? url('storage/' . $user->profile_photo_path) : null,
                'roles' => $user->getRoleNames(),
            ]
        ], 200);
    }
}
