<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ruta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RutaController extends Controller
{
    public function index()
    {
        return response()->json(Ruta::with('creador:id,name')->orderBy('nombre')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|unique:rutas,nombre',
            'chofer' => 'nullable|string',
            'ficha_camion' => 'nullable|string',
        ]);

        $ruta = Ruta::create([
            'nombre' => $request->nombre,
            'chofer' => $request->chofer,
            'ficha_camion' => $request->ficha_camion,
            'created_by' => Auth::id(),
        ]);

        return response()->json($ruta, 201);
    }

    public function update(Request $request, Ruta $ruta)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate([
            'nombre' => 'required|string|unique:rutas,nombre,' . $ruta->id,
            'chofer' => 'nullable|string',
            'ficha_camion' => 'nullable|string',
        ]);

        $ruta->update($request->only(['nombre', 'chofer', 'ficha_camion']));

        return response()->json($ruta);
    }

    public function destroy(Ruta $ruta)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Validate if it has pedidos before deleting
        if (\App\Models\Pedido::where('ruta_id', $ruta->id)->exists()) {
            return response()->json(['message' => 'No se puede eliminar la ruta porque tiene pedidos asociados.'], 400);
        }

        $ruta->delete();
        return response()->json(['message' => 'Ruta eliminada']);
    }
}
