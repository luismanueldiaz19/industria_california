<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventarioCategoria;
use Illuminate\Http\Request;

class InventarioCategoriaController extends Controller
{
    /**
     * Listar todas las categorías activas (con búsqueda opcional).
     * Accessible para todos los usuarios autenticados.
     */
    public function index(Request $request)
    {
        $query = InventarioCategoria::query();

        if ($request->filled('search')) {
            $search = strtoupper(trim($request->input('search')));
            $query->where('nombre', 'LIKE', "%{$search}%");
        }

        if ($request->boolean('solo_activas', true)) {
            $query->where('activo', true);
        }

        return response()->json($query->orderBy('nombre')->get());
    }

    /**
     * Crear una nueva categoría (solo admin).
     */
    public function store(Request $request)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para crear categorías.'], 403);
        }

        $validated = $request->validate([
            'nombre'      => 'required|string|max:120',
            'descripcion' => 'nullable|string|max:500',
            'activo'      => 'boolean',
        ]);

        // La normalización UPPERCASE la hace el mutator del modelo
        if (InventarioCategoria::whereRaw('UPPER(nombre) = ?', [strtoupper(trim($validated['nombre']))])->exists()) {
            return response()->json(['message' => 'Ya existe una categoría con ese nombre.'], 422);
        }

        $categoria = InventarioCategoria::create($validated);

        return response()->json($categoria, 201);
    }

    /**
     * Actualizar una categoría (solo admin).
     */
    public function update(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para editar categorías.'], 403);
        }

        $categoria = InventarioCategoria::findOrFail($id);

        $validated = $request->validate([
            'nombre'      => 'required|string|max:120',
            'descripcion' => 'nullable|string|max:500',
            'activo'      => 'boolean',
        ]);

        // Verificar nombre único excluyendo la categoría actual
        if (InventarioCategoria::whereRaw('UPPER(nombre) = ?', [strtoupper(trim($validated['nombre']))])
            ->where('id', '!=', $id)
            ->exists()) {
            return response()->json(['message' => 'Ya existe una categoría con ese nombre.'], 422);
        }

        $categoria->update($validated);

        return response()->json($categoria);
    }

    /**
     * Eliminar una categoría (solo admin, si no tiene productos asociados).
     */
    public function destroy(Request $request, string $id)
    {
        if (!$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'No tienes permiso para eliminar categorías.'], 403);
        }

        $categoria = InventarioCategoria::findOrFail($id);

        if ($categoria->productos()->count() > 0) {
            return response()->json([
                'message' => 'No se puede eliminar: la categoría tiene productos asociados.'
            ], 422);
        }

        $categoria->delete();

        return response()->json(null, 204);
    }
}
