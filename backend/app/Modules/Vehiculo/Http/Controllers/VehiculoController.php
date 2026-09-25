<?php

namespace App\Modules\Vehiculo\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Vehiculo\Http\Requests\StoreGastoRequest;
use App\Modules\Vehiculo\Http\Requests\StoreMantenimientoRequest;
use App\Modules\Vehiculo\Http\Requests\StoreVehiculoRequest;
use App\Modules\Vehiculo\Http\Requests\UpdateVehiculoRequest;
use App\Modules\Vehiculo\Models\Vehiculo;
use App\Modules\Vehiculo\Models\VehiculoGasto;
use App\Modules\Vehiculo\Models\VehiculoMantenimiento;
use App\Modules\Vehiculo\Services\VehiculoService;
use App\Services\PdfSecurityService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class VehiculoController extends Controller
{
    public function __construct(
        private readonly VehiculoService $service
    ) {}

    // ─── VEHÍCULO (CRUD) ──────────────────────────────────────────

    /**
     * Listar todos los vehículos de la flota.
     * Filtros opcionales: estado, marca, tipo_energia, search.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Vehiculo::query()->with('creador:id,name');

        if ($request->filled('estado') && $request->estado !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('marca')) {
            $query->where('marca', 'like', '%' . $request->marca . '%');
        }

        if ($request->filled('tipo_energia')) {
            $query->where('tipo_energia', $request->tipo_energia);
        }

        if ($request->filled('search')) {
            $busqueda = $request->search;
            $query->where(function ($q) use ($busqueda) {
                $q->where('ficha', 'like', "%{$busqueda}%")
                  ->orWhere('placa', 'like', "%{$busqueda}%")
                  ->orWhere('marca', 'like', "%{$busqueda}%")
                  ->orWhere('modelo', 'like', "%{$busqueda}%");
            });
        }

        return response()->json($query->orderBy('ficha')->get());
    }

    /**
     * Crear un nuevo vehículo.
     */
    public function store(StoreVehiculoRequest $request): JsonResponse
    {
        try {
            $vehiculo = $this->service->crear($request->validated(), Auth::user());
            return response()->json($vehiculo->load('creador:id,name'), 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Ver el detalle de un vehículo con mantenimientos y gastos recientes.
     */
    public function show(Vehiculo $vehiculo): JsonResponse
    {
        return response()->json(
            $vehiculo->load([
                'creador:id,name',
                'mantenimientos' => fn($q) => $q->with('reportador:id,name')->orderBy('fecha_reporte', 'desc'),
                'gastos'         => fn($q) => $q->with('registrador:id,name')->orderBy('fecha_gasto', 'desc'),
            ])
        );
    }

    /**
     * Actualizar los datos de un vehículo.
     */
    public function update(UpdateVehiculoRequest $request, Vehiculo $vehiculo): JsonResponse
    {
        try {
            $vehiculo = $this->service->actualizar($vehiculo, $request->validated());
            return response()->json($vehiculo->load('creador:id,name'), 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Eliminar un vehículo de la flota.
     */
    public function destroy(Vehiculo $vehiculo): JsonResponse
    {
        try {
            $this->service->eliminar($vehiculo);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Resumen estadístico de la flota (conteos por estado).
     */
    public function resumen(): JsonResponse
    {
        return response()->json($this->service->resumenFlota());
    }

    // ─── MANTENIMIENTOS ───────────────────────────────────────────

    /**
     * Listar todos los mantenimientos de todos los vehículos (vista global).
     */
    public function mantenimientosTodos(Request $request): JsonResponse
    {
        $query = VehiculoMantenimiento::with(['vehiculo:id,ficha,placa', 'reportador:id,name']);

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }
        if ($request->filled('tipo')) {
            $query->where('tipo', $request->tipo);
        }

        return response()->json($query->orderBy('fecha_reporte', 'desc')->get());
    }

    /**
     * Obtener URL prefirmada para el PDF de Mantenimientos
     */
    public function getMantenimientosPdfUrl(Request $request): JsonResponse
    {
        $params = $request->only(['estado', 'tipo', 'vehiculo_ficha', 'fecha_inicio', 'fecha_fin']);
        
        $url = PdfSecurityService::generarUrl('mantenimientos_flota', $params, Auth::id(), 30);

        return response()->json(['url' => $url]);
    }

    /**
     * Generar y descargar el PDF
     */
    public function generateMantenimientosPdf(Request $request)
    {
        if (! $request->hasValidSignature()) {
            abort(401, 'URL expirada o inválida');
        }

        $query = VehiculoMantenimiento::with(['vehiculo:id,ficha,placa', 'reportador:id,name']);

        if ($request->filled('estado') && $request->estado !== 'todos' && $request->estado !== 'Todos') {
            $query->where('estado', strtolower(str_replace(' ', '_', $request->estado)));
        }
        if ($request->filled('tipo') && $request->tipo !== 'todos' && $request->tipo !== 'Todos') {
            $query->where('tipo', strtolower($request->tipo));
        }
        if ($request->filled('vehiculo_ficha') && $request->vehiculo_ficha !== 'todos' && $request->vehiculo_ficha !== 'Todos') {
            $query->whereHas('vehiculo', function ($q) use ($request) {
                $q->where('ficha', $request->vehiculo_ficha);
            });
        }
        if ($request->filled('fecha_inicio')) {
            $query->where('fecha_reporte', '>=', $request->fecha_inicio);
        }
        if ($request->filled('fecha_fin')) {
            $query->where('fecha_reporte', '<=', $request->fecha_fin);
        }

        $mantenimientos = $query->orderBy('fecha_reporte', 'desc')->get();
        
        $totalCosto = $mantenimientos->sum('costo');

        // Renderizar el PDF
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.mantenimientos_flota', [
            'mantenimientos' => $mantenimientos,
            'totalCosto'     => $totalCosto,
            'filtros'        => $request->only(['estado', 'tipo', 'vehiculo_ficha', 'fecha_inicio', 'fecha_fin'])
        ]);

        return $pdf->stream('mantenimientos_flota.pdf');
    }

    /**
     * Listar los mantenimientos de un vehículo.
     */
    public function mantenimientosIndex(Vehiculo $vehiculo, Request $request): JsonResponse
    {
        $query = $vehiculo->mantenimientos()->with('reportador:id,name');

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('tipo')) {
            $query->where('tipo', $request->tipo);
        }

        return response()->json($query->orderBy('fecha_reporte', 'desc')->get());
    }

    /**
     * Registrar un nuevo mantenimiento para un vehículo.
     */
    public function mantenimientosStore(StoreMantenimientoRequest $request, Vehiculo $vehiculo): JsonResponse
    {
        try {
            $mantenimiento = $this->service->registrarMantenimiento(
                $vehiculo,
                $request->validated(),
                Auth::user()
            );
            return response()->json($mantenimiento, 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Actualizar un mantenimiento existente.
     */
    public function mantenimientosUpdate(Request $request, Vehiculo $vehiculo, VehiculoMantenimiento $mantenimiento): JsonResponse
    {
        $datos = $request->validate([
            'tipo'          => 'nullable|in:preventivo,correctivo,averia',
            'fecha_reporte' => 'nullable|date',
            'descripcion'   => 'nullable|string|max:1000',
            'costo'         => 'nullable|numeric|min:0',
            'estado'        => 'nullable|in:pendiente,en_proceso,resuelto',
            'evidencias'    => 'nullable|array',
        ]);

        try {
            $mantenimiento = $this->service->actualizarMantenimiento($vehiculo, $mantenimiento, $datos);
            return response()->json($mantenimiento, 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Eliminar un mantenimiento.
     */
    public function mantenimientosDestroy(Vehiculo $vehiculo, VehiculoMantenimiento $mantenimiento): JsonResponse
    {
        try {
            $this->service->eliminarMantenimiento($mantenimiento);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    // ─── GASTOS Y COMBUSTIBLE ─────────────────────────────────────
    
    /**
     * Listar todos los gastos de todos los vehículos (vista global).
     */
    public function gastosTodos(Request $request): JsonResponse
    {
        $query = VehiculoGasto::with(['vehiculo:id,ficha,placa', 'registrador:id,name']);

        if ($request->filled('tipo_gasto')) {
            $query->where('tipo_gasto', $request->tipo_gasto);
        }
        
        if ($request->filled('fecha_desde')) {
            $query->where('fecha_gasto', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_gasto', '<=', $request->fecha_hasta);
        }

        return response()->json($query->orderBy('fecha_gasto', 'desc')->get());
    }

    /**
     * Obtener URL prefirmada para el PDF de Gastos
     */
    public function getGastosPdfUrl(Request $request): JsonResponse
    {
        $params = $request->only(['tipo_gasto', 'vehiculo_ficha', 'fecha_inicio', 'fecha_fin']);
        
        $url = PdfSecurityService::generarUrl('gastos_flota', $params, Auth::id(), 30);

        return response()->json(['url' => $url]);
    }

    /**
     * Estadísticas de gastos por año para gráficos
     */
    public function gastosEstadisticas(Request $request): JsonResponse
    {
        $year = (int) ($request->get('year', date('Y')));

        $gastos = VehiculoGasto::with('vehiculo:id,ficha')
            ->whereYear('fecha_gasto', $year)
            ->get();

        // 1. Total por mes
        $porMes = array_fill(1, 12, 0.0);
        foreach ($gastos as $g) {
            $mes = (int) $g->fecha_gasto->format('n');
            $porMes[$mes] += (float) $g->monto_total;
        }

        // 2. Total mensual por vehículo
        $porVehiculo = [];
        foreach ($gastos as $g) {
            $ficha = $g->vehiculo?->ficha ?? 'S/N';
            $mes   = (int) $g->fecha_gasto->format('n');
            $porVehiculo[$ficha][$mes] = ($porVehiculo[$ficha][$mes] ?? 0) + (float) $g->monto_total;
        }

        // 3. Total mensual por tipo de gasto
        $porTipo = [];
        foreach ($gastos as $g) {
            $tipo = $g->tipo_gasto ?? 'Sin tipo';
            $mes  = (int) $g->fecha_gasto->format('n');
            $porTipo[$tipo][$mes] = ($porTipo[$tipo][$mes] ?? 0) + (float) $g->monto_total;
        }

        return response()->json([
            'year'         => $year,
            'por_mes'      => $porMes,
            'por_vehiculo' => $porVehiculo,
            'por_tipo'     => $porTipo,
            'total_year'   => $gastos->sum('monto_total'),
        ]);
    }

    /**
     * Generar y descargar el PDF de Gastos
     */
    public function generateGastosPdf(Request $request)
    {
        if (! $request->hasValidSignature()) {
            abort(401, 'URL expirada o inválida');
        }

        $query = VehiculoGasto::with(['vehiculo:id,ficha,placa', 'registrador:id,name']);

        if ($request->filled('tipo_gasto') && $request->tipo_gasto !== 'todos' && $request->tipo_gasto !== 'Todos') {
            $query->where('tipo_gasto', strtolower($request->tipo_gasto));
        }
        if ($request->filled('vehiculo_ficha') && $request->vehiculo_ficha !== 'todos' && $request->vehiculo_ficha !== 'Todos') {
            $query->whereHas('vehiculo', function ($q) use ($request) {
                $q->where('ficha', $request->vehiculo_ficha);
            });
        }
        if ($request->filled('fecha_inicio')) {
            $query->where('fecha_gasto', '>=', $request->fecha_inicio);
        }
        if ($request->filled('fecha_fin')) {
            $query->where('fecha_gasto', '<=', $request->fecha_fin);
        }

        $gastos = $query->orderBy('fecha_gasto', 'desc')->get();
        
        $totalMonto = $gastos->sum('monto_total');

        // Renderizar el PDF
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.gastos_flota', [
            'gastos' => $gastos,
            'totalMonto' => $totalMonto,
            'filtros' => $request->only(['tipo_gasto', 'vehiculo_ficha', 'fecha_inicio', 'fecha_fin'])
        ]);

        return $pdf->stream('gastos_flota.pdf');
    }

    /**
     * Listar los gastos de un vehículo.
     */
    public function gastosIndex(Vehiculo $vehiculo, Request $request): JsonResponse
    {
        $query = $vehiculo->gastos()->with('registrador:id,name');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_gasto', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_gasto', '<=', $request->fecha_hasta);
        }

        if ($request->filled('concepto')) {
            $query->where('concepto', 'like', '%' . $request->concepto . '%');
        }

        return response()->json($query->orderBy('fecha_gasto', 'desc')->get());
    }

    /**
     * Registrar un nuevo gasto para un vehículo.
     */
    public function gastosStore(StoreGastoRequest $request, Vehiculo $vehiculo): JsonResponse
    {
        try {
            $gasto = $this->service->registrarGasto($vehiculo, $request->validated(), Auth::user());
            return response()->json($gasto->load('registrador:id,name'), 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Actualizar un gasto registrado.
     */
    public function gastosUpdate(Request $request, Vehiculo $vehiculo, VehiculoGasto $gasto): JsonResponse
    {
        $datos = $request->validate([
            'tipo_gasto'      => 'nullable|string|max:100',
            'fecha_gasto'     => 'nullable|date',
            'concepto'        => 'nullable|string|max:255',
            'cantidad'        => 'nullable|numeric|min:0',
            'unidad_medida'   => 'nullable|string|max:50',
            'precio_unitario' => 'nullable|numeric|min:0',
            'monto_total'     => 'nullable|numeric|min:0',
            'comprobantes'    => 'nullable|array',
        ]);

        try {
            $gasto = $this->service->actualizarGasto($gasto, $datos);
            return response()->json($gasto->load('registrador:id,name'), 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * Eliminar un gasto.
     */
    public function gastosDestroy(Vehiculo $vehiculo, VehiculoGasto $gasto): JsonResponse
    {
        try {
            $this->service->eliminarGasto($gasto);
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
