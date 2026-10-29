<?php

namespace App\Modules\Nomina\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Nomina\Models\NominaConcepto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NominaConceptoController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = NominaConcepto::query();

        if ($request->filled('tipo')) {
            $query->where('tipo', $request->query('tipo'));
        }

        if ($request->filled('categoria')) {
            $query->where('categoria', $request->query('categoria'));
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->query('activo'), FILTER_VALIDATE_BOOLEAN));
        }

        return response()->json($query->orderBy('tipo')->orderBy('nombre')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'codigo'           => 'required|string|max:50|unique:nomina_conceptos,codigo',
            'nombre'           => 'required|string|max:120',
            'tipo'             => 'required|in:ingreso,deduccion',
            'categoria'        => 'nullable|string|max:40',
            'es_automatico'    => 'nullable|boolean',
            'es_porcentual'    => 'nullable|boolean',
            'porcentaje'       => 'nullable|numeric|min:0',
            'es_cotizable_tss' => 'nullable|boolean',
            'es_gravable_isr'  => 'nullable|boolean',
            'activo'           => 'nullable|boolean',
        ]);

        $concepto = NominaConcepto::create($validated);
        return response()->json($concepto, 201);
    }

    public function update(Request $request, NominaConcepto $nominaConcepto): JsonResponse
    {
        $validated = $request->validate([
            'nombre'           => 'nullable|string|max:120',
            'categoria'        => 'nullable|string|max:40',
            'es_porcentual'    => 'nullable|boolean',
            'porcentaje'       => 'nullable|numeric|min:0',
            'es_cotizable_tss' => 'nullable|boolean',
            'es_gravable_isr'  => 'nullable|boolean',
            'activo'           => 'nullable|boolean',
        ]);

        $nominaConcepto->update($validated);
        return response()->json($nominaConcepto);
    }

    public function destroy(NominaConcepto $nominaConcepto): JsonResponse
    {
        if ($nominaConcepto->es_automatico) {
            return response()->json(['message' => 'Los conceptos automáticos del sistema no pueden eliminarse.'], 422);
        }

        $nominaConcepto->delete();
        return response()->json(['message' => 'Concepto eliminado correctamente.']);
    }
}

