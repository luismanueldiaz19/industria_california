<?php

namespace App\Modules\Nomina\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Nomina\Models\Nomina;
use App\Modules\Nomina\Services\NominaService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NominaController extends Controller
{
    public function __construct(
        private readonly NominaService $service
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Nomina::query()
            ->with(['creador:id,name', 'aprobador:id,name'])
            ->withCount('detalles');

        if ($request->filled('estado')) {
            $query->where('estado', $request->query('estado'));
        }

        if ($request->filled('tipo_periodo')) {
            $query->where('tipo_periodo', $request->query('tipo_periodo'));
        }

        if ($request->filled('anio')) {
            $query->whereYear('fecha_pago', $request->query('anio'));
        }

        return response()->json($query->orderBy('fecha_pago', 'desc')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'titulo'       => 'required|string|max:150',
            'tipo_periodo' => 'required|in:quincenal,mensual,extraordinaria',
            'fecha_inicio' => 'required|date',
            'fecha_fin'    => 'required|date|after_or_equal:fecha_inicio',
            'fecha_pago'   => 'required|date',
            'notas'        => 'nullable|string',
        ]);

        try {
            $nomina = $this->service->crearPeriodo($validated, Auth::user());
            return response()->json($nomina, 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show(Nomina $nomina): JsonResponse
    {
        return response()->json(
            $nomina->load([
                'creador:id,name',
                'aprobador:id,name',
                'detalles.empleado',
                'detalles.conceptos.concepto',
            ])
        );
    }

    public function calcular(Nomina $nomina): JsonResponse
    {
        try {
            $calculada = $this->service->calcularNomina($nomina);
            return response()->json($calculada);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function aprobar(Nomina $nomina): JsonResponse
    {
        try {
            $aprobada = $this->service->aprobarNomina($nomina, Auth::user());
            return response()->json($aprobada);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function pagar(Nomina $nomina): JsonResponse
    {
        try {
            $pagada = $this->service->pagarNomina($nomina, Auth::user());
            return response()->json($pagada);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function anular(Request $request, Nomina $nomina): JsonResponse
    {
        $validated = $request->validate([
            'motivo' => 'nullable|string|max:255',
        ]);

        try {
            $anulada = $this->service->anularNomina($nomina, Auth::user(), $validated['motivo'] ?? null);
            return response()->json($anulada);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumen());
    }

    public function escalasIsr(Request $request): JsonResponse
    {
        $anio = $request->filled('anio') ? (int) $request->query('anio') : null;
        return response()->json($this->service->getEscalasIsr($anio));
    }

    public function destroy(Nomina $nomina): JsonResponse
    {
        if ($nomina->estado->value === 'pagada') {
            return response()->json(['message' => 'No se puede eliminar una nómina pagada.'], 422);
        }

        $nomina->delete();
        return response()->json(['message' => 'Nómina eliminada con éxito.']);
    }
}

