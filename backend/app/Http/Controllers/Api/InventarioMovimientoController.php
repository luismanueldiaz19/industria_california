<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventarioMovimiento;
use App\Models\InventarioProducto;
use App\Services\PdfSecurityService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InventarioMovimientoController extends Controller
{
    /**
     * Listar movimientos con filtros y paginación.
     */
    public function index(Request $request)
    {
        $query = InventarioMovimiento::with(['producto:id,codigo,nombre,unidad', 'user:id,name,username']);

        if ($request->filled('producto_id')) {
            $query->where('producto_id', $request->input('producto_id'));
        }

        if ($request->filled('tipo')) {
            $query->where('tipo', strtoupper($request->input('tipo')));
        }

        if ($request->filled('start_date')) {
            $query->whereDate('created_at', '>=', $request->input('start_date'));
        }

        if ($request->filled('end_date')) {
            $query->whereDate('created_at', '<=', $request->input('end_date'));
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->input('user_id'));
        }

        $query->orderBy('created_at', 'desc');

        $perPage   = (int) $request->input('per_page', 30);
        $perPage   = min(max($perPage, 5), 100);

        $resumenQuery = clone $query;
        $resumen = $resumenQuery->reorder()->select('tipo', DB::raw('SUM(cantidad) as total_cantidad'))
            ->groupBy('tipo')
            ->pluck('total_cantidad', 'tipo');

        $paginated = $query->paginate($perPage);

        return response()->json([
            'data'         => $paginated->items(),
            'current_page' => $paginated->currentPage(),
            'last_page'    => $paginated->lastPage(),
            'total'        => $paginated->total(),
            'resumen'      => $resumen,
        ]);
    }

    /**
     * Registrar un movimiento de inventario.
     * Actualiza el stock del producto de forma atómica.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'producto_id' => 'required|exists:inventario_productos,id',
            'tipo'        => 'required|in:AJUSTE,PRODUCCION,VENTA,BAJA',
            'subtipo'     => 'nullable|string|in:MALO,PERDIDO,DAÑADO',
            'cantidad'    => 'required|numeric|not_in:0',
            'nota'        => 'nullable|string|max:500',
        ]);

        return DB::transaction(function () use ($validated, $request) {
            // Bloquear el producto para escritura (SELECT FOR UPDATE)
            $producto = InventarioProducto::lockForUpdate()->findOrFail($validated['producto_id']);

            $stockAnterior   = (float) $producto->stock;
            $cantidad        = (float) $validated['cantidad'];
            $stockResultante = $stockAnterior + $cantidad;

            // Actualizar stock del producto
            $producto->update(['stock' => $stockResultante]);

            // Registrar el movimiento
            $movimiento = InventarioMovimiento::create([
                'producto_id'      => $producto->id,
                'user_id'          => $request->user()->id,
                'tipo'             => $validated['tipo'],
                'subtipo'          => $validated['subtipo'] ?? null,
                'cantidad'         => $cantidad,
                'stock_anterior'   => $stockAnterior,
                'stock_resultante' => $stockResultante,
                'nota'             => $validated['nota'] ?? null,
            ]);

            return response()->json($movimiento->load(['producto:id,codigo,nombre', 'user:id,name']), 201);
        });
    }

    /**
     * Genera URL segura para PDF de movimientos.
     */
    public function getMovimientoPdfUrl(Request $request)
    {
        $params = [];
        foreach (['producto_id', 'tipo', 'start_date', 'end_date', 'user_id'] as $key) {
            if ($request->filled($key)) {
                $params[$key] = $request->input($key);
            }
        }

        $url = PdfSecurityService::generarUrl(
            'inventario_movimientos',
            $params,
            $request->user()->id,
            30
        );

        return response()->json(['url' => $url]);
    }
}
