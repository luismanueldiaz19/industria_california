<?php

namespace App\Modules\Nomina\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Nomina\Models\NominaEmpleadoRecurrente;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NominaEmpleadoRecurrenteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = NominaEmpleadoRecurrente::with(['empleado', 'concepto']);

        if ($request->filled('empleado_id')) {
            $query->where('empleado_id', $request->query('empleado_id'));
        }

        if ($request->filled('activo')) {
            $query->where('activo', filter_var($request->query('activo'), FILTER_VALIDATE_BOOLEAN));
        }

        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'empleado_id'    => 'required|exists:empleados,id',
            'concepto_id'    => 'required|exists:nomina_conceptos,id',
            'descripcion'    => 'required|string|max:150',
            'monto_total'    => 'required|numeric|min:0',
            'monto_cuota'    => 'required|numeric|min:0.01',
            'cuotas_totales' => 'required|integer|min:1',
            'cuotas_pagadas' => 'nullable|integer|min:0',
            'saldo_restante' => 'nullable|numeric|min:0',
        ]);

        if (!isset($validated['saldo_restante'])) {
            $validated['saldo_restante'] = $validated['monto_total'];
        }

        $validated['activo'] = true;

        $recurrente = NominaEmpleadoRecurrente::create($validated);
        return response()->json($recurrente->load(['empleado', 'concepto']), 201);
    }

    public function update(Request $request, NominaEmpleadoRecurrente $recurrente): JsonResponse
    {
        $validated = $request->validate([
            'descripcion'    => 'nullable|string|max:150',
            'monto_cuota'    => 'nullable|numeric|min:0.01',
            'saldo_restante' => 'nullable|numeric|min:0',
            'activo'         => 'nullable|boolean',
        ]);

        $recurrente->update($validated);
        return response()->json($recurrente->fresh(['empleado', 'concepto']));
    }

    public function destroy(NominaEmpleadoRecurrente $recurrente): JsonResponse
    {
        $recurrente->delete();
        return response()->json(['message' => 'Descuento recurrente eliminado.']);
    }
}

