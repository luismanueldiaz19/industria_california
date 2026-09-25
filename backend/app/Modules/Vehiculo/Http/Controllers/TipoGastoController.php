<?php

namespace App\Modules\Vehiculo\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Vehiculo\Models\TipoGasto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TipoGastoController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(TipoGasto::orderBy('nombre')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['nombre' => 'required|string|unique:tipo_gastos,nombre|max:100']);
        $tipo = TipoGasto::create($request->only('nombre'));
        return response()->json($tipo, 201);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $tipo = TipoGasto::findOrFail($id);
        $request->validate(['nombre' => 'required|string|unique:tipo_gastos,nombre,' . $tipo->id . '|max:100']);
        $tipo->update($request->only('nombre'));
        return response()->json($tipo, 200);
    }

    public function destroy($id): JsonResponse
    {
        $tipo = TipoGasto::findOrFail($id);
        $tipo->delete();
        return response()->json(null, 204);
    }
}
