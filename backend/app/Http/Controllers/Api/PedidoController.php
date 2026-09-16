<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pedido;
use App\Models\PedidoDetalle;
use App\Models\InventarioProducto;
use App\Models\InventarioMovimiento;
use App\Models\OrdenProduccion;
use App\Models\OrdenProduccionDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Services\PdfSecurityService;



class PedidoController extends Controller
{
    public function index(Request $request)
    {
        $query = Pedido::with([
            'cliente:id,nombre',
            'ruta:id,nombre',
            'vendedor:id,name',
            'facturador:id,name',
            'detalles.producto:id,codigo,nombre,imagen_producto,unidad'
        ]);

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->input('cliente_id'));
        }
        if ($request->filled('ruta_id')) {
            $query->where('ruta_id', $request->input('ruta_id'));
        }
        if ($request->filled('estado')) {
            $query->where('estado', $request->input('estado'));
        }
        if ($request->filled('start_date') || $request->filled('end_date')) {
            if ($request->filled('start_date')) {
                $query->whereDate('created_at', '>=', $request->input('start_date'));
            }
            if ($request->filled('end_date')) {
                $query->whereDate('created_at', '<=', $request->input('end_date'));
            }
        } else {
            // Default filter if no date is selected:
            // Only today's records OR pending/draft records
            $query->where(function ($q) {
                $q->whereDate('created_at', now()->toDateString())
                  ->orWhereIn('estado', ['borrador', 'enviado']);
            });
        }

        if ($request->input('has_faltantes') == '1' || $request->input('has_faltantes') == 'true') {
            $query->whereHas('detalles', function ($q) {
                $q->where('cantidad_en_produccion', '>', 0);
            });
        }

        // Vendedor can only see their own orders unless they are admin
        if (!Auth::user()->hasRole('admin')) {
            $query->where('vendedor_id', Auth::id());
        } else {
            // If admin and they provided a vendedor_id filter, apply it
            if ($request->filled('vendedor_id')) {
                $query->where('vendedor_id', $request->input('vendedor_id'));
            }
        }

        $query->orderBy('created_at', 'desc');

        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        return response()->json($query->paginate($perPage));
    }

    public function store(Request $request)
    {
        $request->validate([
            'cliente_id' => 'required|exists:ledhouse_clientes,id',
            'ruta_id' => 'nullable|exists:rutas,id',
            'comentario' => 'nullable|string',
            'estado' => 'required|in:borrador,enviado',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:inventario_productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.observacion' => 'nullable|string',
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
        ]);

        try {
            DB::beginTransaction();

            $total = 0;
            $detallesToInsert = [];

            foreach ($request->detalles as $detalle) {
                $producto = InventarioProducto::findOrFail($detalle['producto_id']);
                $precioEnviado = (float) $detalle['precio_unitario'];
                $precioBase = (float) $producto->venta;

                // Validate ±20% constraint
                if ($precioBase > 0) {
                    $minPrice = $precioBase * 0.8;
                    $maxPrice = $precioBase * 1.2;
                    
                    if ($precioEnviado < $minPrice || $precioEnviado > $maxPrice) {
                        return response()->json([
                            'message' => "El precio del producto {$producto->nombre} ({$precioEnviado}) excede el límite del 20% sobre el precio base ({$precioBase})."
                        ], 422);
                    }
                }

                $subtotal = $precioEnviado * $detalle['cantidad'];
                $total += $subtotal;

                // Calculamos un faltante estimado para mostrar en borrador (sin lock aún)
                $stockActual = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle['cantidad'];
                $faltanteEstimado = max(0, $cantidadSolicitada - $stockActual);

                $detallesToInsert[] = [
                    'producto_id' => $producto->id,
                    'cantidad' => $detalle['cantidad'],
                    'precio_unitario' => $precioEnviado,
                    'subtotal' => $subtotal,
                    'observacion' => $detalle['observacion'] ?? null,
                    'cantidad_en_produccion' => $faltanteEstimado,
                ];
            }

            $pedido = Pedido::create([
                'cliente_id' => $request->cliente_id,
                'ruta_id' => $request->ruta_id,
                'vendedor_id' => Auth::id(),
                'estado' => $request->estado,
                'comentario' => $request->comentario,
                'total' => $total,
                'latitud' => $request->latitud,
                'longitud' => $request->longitud,
            ]);

            $pedidoDetallesModels = [];
            foreach ($detallesToInsert as $det) {
                $det['pedido_id'] = $pedido->id;
                $pedidoDetallesModels[$det['producto_id']] = PedidoDetalle::create($det);
            }

            // Eliminada la lógica de creación automática de OrdenProduccion desde el JSON.
            // Los faltantes se manejan automáticamente al pasar a estado "enviado".

            if ($request->estado === 'enviado') {
                $this->_deducirInventario($pedido->load('detalles'));
            }

            DB::commit();
            return response()->json($pedido->load('detalles'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al crear pedido', 'error' => $e->getMessage()], 500);
        }
    }

    public function update(Request $request, Pedido $pedido)
    {
        // Only draft orders can be completely updated by the vendor
        if ($pedido->estado !== 'borrador' && !Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No puedes editar un pedido que ya no es borrador.'], 403);
        }

        $request->validate([
            'cliente_id' => 'required|exists:ledhouse_clientes,id',
            'ruta_id' => 'nullable|exists:rutas,id',
            'comentario' => 'nullable|string',
            'estado' => 'required|in:borrador,enviado',
            'detalles' => 'required|array|min:1',
            'detalles.*.producto_id' => 'required|exists:inventario_productos,id',
            'detalles.*.cantidad' => 'required|numeric|min:0.01',
            'detalles.*.precio_unitario' => 'required|numeric|min:0',
            'detalles.*.observacion' => 'nullable|string',
            'latitud' => 'nullable|numeric',
            'longitud' => 'nullable|numeric',
            'fecha_entrega' => 'nullable|date',
            'nota_produccion' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $originalEstado = $pedido->estado;

            $total = 0;
            $pedido->detalles()->delete(); // Clear old ones to easily sync

            foreach ($request->detalles as $detalle) {
                $producto = InventarioProducto::findOrFail($detalle['producto_id']);
                $precioEnviado = (float) $detalle['precio_unitario'];
                $precioBase = (float) $producto->venta;

                if ($precioBase > 0) {
                    $minPrice = $precioBase * 0.8;
                    $maxPrice = $precioBase * 1.2;
                    if ($precioEnviado < $minPrice || $precioEnviado > $maxPrice) {
                        return response()->json([
                            'message' => "El precio del producto {$producto->nombre} ({$precioEnviado}) excede el límite del 20% sobre el precio base ({$precioBase})."
                        ], 422);
                    }
                }

                $subtotal = $precioEnviado * $detalle['cantidad'];
                $total += $subtotal;

                $stockActual = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle['cantidad'];
                $faltanteEstimado = max(0, $cantidadSolicitada - $stockActual);

                PedidoDetalle::create([
                    'pedido_id' => $pedido->id,
                    'producto_id' => $producto->id,
                    'cantidad' => $detalle['cantidad'],
                    'precio_unitario' => $precioEnviado,
                    'subtotal' => $subtotal,
                    'observacion' => $detalle['observacion'] ?? null,
                    'cantidad_en_produccion' => $faltanteEstimado,
                ]);
            }

            $pedido->update([
                'cliente_id' => $request->cliente_id,
                'ruta_id' => $request->ruta_id,
                'estado' => $request->estado,
                'comentario' => $request->comentario,
                'total' => $total,
                'latitud' => $request->latitud,
                'longitud' => $request->longitud,
                'fecha_entrega' => $request->fecha_entrega,
                'nota_produccion' => $request->nota_produccion,
            ]);

            if ($originalEstado === 'borrador' && $request->estado === 'enviado') {
                $this->_deducirInventario($pedido->load('detalles'));
            }

            DB::commit();
            return response()->json($pedido->load('detalles'));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al actualizar pedido', 'error' => $e->getMessage()], 500);
        }
    }

    public function destroy(Pedido $pedido)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado para eliminar pedidos.'], 403);
        }

        $pedido->delete();
        return response()->json(['message' => 'Pedido eliminado correctamente.']);
    }

    public function changeStatus(Request $request, Pedido $pedido)
    {
        $request->validate([
            'estado' => 'required|in:borrador,enviado,facturado,cancelado'
        ]);

        $nuevoEstado = $request->estado;
        
        // Vendedores can only change from borrador to enviado
        if (!Auth::user()->hasRole('admin')) {
            if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                return response()->json(['message' => 'No autorizado para facturar o cancelar.'], 403);
            }
        }

        if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
            $pedido->facturador_id = Auth::id();
        }

        $estadoAnterior = $pedido->estado;

        try {
            DB::beginTransaction();

            $pedido->estado = $nuevoEstado;
            $pedido->save();

            if ($estadoAnterior === 'borrador' && $nuevoEstado === 'enviado') {
                $this->_deducirInventario($pedido->load('detalles'));
            }

            DB::commit();
            return response()->json($pedido);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al cambiar estado', 'error' => $e->getMessage()], 500);
        }
    }
    public function getGeneralPdfUrl(Request $request)
    {
        $params = $request->only(['cliente_id', 'ruta_id', 'vendedor_id', 'estado', 'start_date', 'end_date']);
        if (!Auth::user()->hasRole('admin')) {
            $params['vendedor_id'] = Auth::id();
        }
        $url = PdfSecurityService::generarUrl('pedidos_general', $params, Auth::id(), 30);
        return response()->json(['url' => $url]);
    }

    public function getPdfUrl($id)
    {
        $pedido = Pedido::findOrFail($id);
        if (!Auth::user()->hasRole('admin') && $pedido->vendedor_id !== Auth::id()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $url = PdfSecurityService::generarUrl('pedido', ['id' => $id], Auth::id(), 30);
        
        return response()->json(['url' => $url]);
    }

    public function generatePdf($id)
    {
        $pedido = Pedido::with([
            'cliente:id,nombre,direccion,telefono,rnc', 
            'ruta:id,nombre', 
            'vendedor:id,name', 
            'detalles.producto:id,codigo,nombre,unidad'
        ])->findOrFail($id);

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.pedido_factura', compact('pedido'));
        return $pdf->stream("pedido_{$pedido->id}.pdf");
    }

    public function assignRuta(Request $request)
    {
        if (!Auth::user()->hasRole('admin')) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate([
            'pedido_ids' => 'required|array|min:1',
            'pedido_ids.*' => 'exists:pedidos,id',
            'ruta_id' => 'required|exists:rutas,id',
        ]);

        Pedido::whereIn('id', $request->pedido_ids)->update(['ruta_id' => $request->ruta_id]);

        return response()->json(['message' => 'Pedidos asignados a la ruta correctamente.']);
    }

    public function optimizeDayRoute(Request $request)
    {
        $request->validate([
            'ruta_id' => 'required|exists:rutas,id',
            'date' => 'nullable|date',
            'origin_lat' => 'required|numeric',
            'origin_lng' => 'required|numeric'
        ]);

        $date = $request->input('date', date('Y-m-d'));
        
        $pedidos = Pedido::with(['cliente:id,nombre,direccion,latitud,longitud', 'ruta:id,nombre'])
            ->where('ruta_id', $request->ruta_id)
            ->whereDate('created_at', $date)
            ->get();
            
        if ($pedidos->isEmpty()) {
            return response()->json([]);
        }

        // Greedy TSP using Haversine
        $origin = ['lat' => (float) $request->origin_lat, 'lng' => (float) $request->origin_lng];
        $unvisited = $pedidos->toArray();
        $ordered = [];

        $currentPos = $origin;

        while(count($unvisited) > 0) {
            $nearestIndex = -1;
            $minDist = PHP_FLOAT_MAX;

            foreach($unvisited as $index => $pedido) {
                // Fallback to client location if pedido location is missing
                $lat = $pedido['latitud'] ?? $pedido['cliente']['latitud'] ?? null;
                $lng = $pedido['longitud'] ?? $pedido['cliente']['longitud'] ?? null;

                if ($lat === null || $lng === null) {
                    $dist = PHP_FLOAT_MAX - 1; // Send to end of route
                } else {
                    $dist = $this->haversineGreatCircleDistance(
                        $currentPos['lat'], $currentPos['lng'], 
                        (float)$lat, (float)$lng
                    );
                }

                if ($dist < $minDist) {
                    $minDist = $dist;
                    $nearestIndex = $index;
                }
            }

            $nearest = $unvisited[$nearestIndex];
            $ordered[] = $nearest;
            
            $nearestLat = $nearest['latitud'] ?? $nearest['cliente']['latitud'] ?? null;
            $nearestLng = $nearest['longitud'] ?? $nearest['cliente']['longitud'] ?? null;
            if ($nearestLat !== null && $nearestLng !== null) {
                $currentPos = ['lat' => (float)$nearestLat, 'lng' => (float)$nearestLng];
            }
            
            unset($unvisited[$nearestIndex]);
            $unvisited = array_values($unvisited);
        }

        return response()->json($ordered);
    }

    private function haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo, $earthRadius = 6371000)
    {
        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo = deg2rad($latitudeTo);
        $lonTo = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
        
        return $angle * $earthRadius;
    }

    // ── Reporte agrupado por vendedor ─────────────────────────────────────
    public function reporteVendedores(Request $request)
    {
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');
        $search    = $request->input('search');
        $mesFmt    = $this->_mesFmtExpr('pedidos.created_at');

        // ── Scope base reutilizable usando el modelo Pedido ──
        $scope = Pedido::query()
            ->with('vendedor:id,name')
            ->when($startDate, fn($q) => $q->whereDate('pedidos.created_at', '>=', $startDate))
            ->when($endDate,   fn($q) => $q->whereDate('pedidos.created_at', '<=', $endDate))
            ->when($search, fn($q) =>
                $q->whereHas('vendedor', fn($vq) =>
                    $vq->whereRaw('LOWER(name) LIKE ?', ['%' . mb_strtolower($search) . '%'])
                )
            )
            ->when(!Auth::user()->hasRole('admin'), fn($q) =>
                $q->where('vendedor_id', Auth::id())
            );

        // ── Totales agrupados por vendedor (paginados) ──
        $perPage = min(max((int) $request->input('per_page', 10), 3), 50);

        $paginated = (clone $scope)
            ->select(
                'vendedor_id',
                DB::raw('COUNT(id) as total_pedidos'),
                DB::raw('SUM(total) as total_monto'),
                DB::raw("SUM(CASE WHEN estado = 'borrador'  THEN 1 ELSE 0 END) as borrador"),
                DB::raw("SUM(CASE WHEN estado = 'enviado'   THEN 1 ELSE 0 END) as enviado"),
                DB::raw("SUM(CASE WHEN estado = 'facturado' THEN 1 ELSE 0 END) as facturado"),
                DB::raw("SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) as cancelado")
            )
            ->groupBy('vendedor_id')
            ->orderByDesc('total_monto')
            ->with('vendedor:id,name')
            ->paginate($perPage);

        // Enriquecer cada item con el nombre del vendedor
        $paginated->getCollection()->transform(function ($item) use ($scope) {
            $item->vendedor_nombre = $item->vendedor?->name ?? 'Sin asignar';
            
            // Calculate real faltante for this vendor based on the same scope
            $faltante = (clone $scope)
                ->where('pedidos.vendedor_id', $item->vendedor_id)
                ->join('pedido_detalles', 'pedidos.id', '=', 'pedido_detalles.pedido_id')
                ->sum(\DB::raw('pedido_detalles.cantidad_en_produccion * pedido_detalles.precio_unitario'));

            $item->total_faltante = (float)$faltante;
            $item->total_real = $item->total_monto - (float)$faltante;

            unset($item->vendedor);
            return $item;
        });

        // ── Gráfico 1: pedidos totales por mes ──
        $graficoMeses = (clone $scope)
            ->selectRaw("{$mesFmt} as mes, COUNT(id) as total_pedidos, SUM(total) as total_monto")
            ->groupBy('mes')
            ->orderBy('mes')
            ->get()
            ->map(fn($row) => [
                'mes'           => $row->mes,
                'mes_label'     => \Carbon\Carbon::parse($row->mes . '-01')->translatedFormat('M Y'),
                'total_pedidos' => (int)   $row->total_pedidos,
                'total_monto'   => (float) $row->total_monto,
            ]);

        // ── Gráfico 2: pedidos por vendedor × mes ──
        // Query propia con columnas calificadas para evitar ambigüedad al hacer join.
        $graficoVendedoresMeses = Pedido::query()
            ->join('users as v', 'pedidos.vendedor_id', '=', 'v.id')
            ->when($startDate, fn($q) => $q->whereDate('pedidos.created_at', '>=', $startDate))
            ->when($endDate,   fn($q) => $q->whereDate('pedidos.created_at', '<=', $endDate))
            ->when($search, fn($q) =>
                $q->whereRaw('LOWER(v.name) LIKE ?', ['%' . mb_strtolower($search) . '%'])
            )
            ->when(!Auth::user()->hasRole('admin'), fn($q) =>
                $q->where('pedidos.vendedor_id', Auth::id())
            )
            ->selectRaw("v.name as vendedor_nombre, {$mesFmt} as mes, COUNT(pedidos.id) as total_pedidos, SUM(pedidos.total) as total_monto")
            ->groupBy('v.name', 'mes')
            ->orderBy('mes')
            ->get();

        // ── Resumen general ──
        $resumen = (clone $scope)
            ->selectRaw('COUNT(id) as total_pedidos, SUM(total) as total_monto, COUNT(DISTINCT vendedor_id) as total_vendedores')
            ->first();

        $totalFaltanteGeneral = (clone $scope)
            ->join('pedido_detalles', 'pedidos.id', '=', 'pedido_detalles.pedido_id')
            ->sum(\DB::raw('pedido_detalles.cantidad_en_produccion * pedido_detalles.precio_unitario'));

        return response()->json([
            'vendedores'               => $paginated,
            'grafico_meses'            => $graficoMeses,
            'grafico_vendedores_meses' => $graficoVendedoresMeses,
            'resumen' => [
                'total_pedidos'    => (int)   ($resumen->total_pedidos    ?? 0),
                'total_monto'      => (float) ($resumen->total_monto      ?? 0),
                'total_faltante'   => (float) $totalFaltanteGeneral,
                'total_real'       => (float) (($resumen->total_monto ?? 0) - $totalFaltanteGeneral),
                'total_vendedores' => (int)   ($resumen->total_vendedores ?? 0),
            ],
        ]);
    }

    public function getReporteVendedoresPdfUrl(Request $request)
    {
        $params = $request->only(['start_date', 'end_date', 'search']);
        if (!Auth::user()->hasRole('admin')) {
            $params['vendedor_id'] = Auth::id();
        }
        $url = PdfSecurityService::generarUrl('pedidos_vendedores', $params, Auth::id(), 30);
        return response()->json(['url' => $url]);
    }

    private function _deducirInventario(Pedido $pedido)
    {
        $detallesFaltantes = [];

        foreach ($pedido->detalles as $detalle) {
            $producto = InventarioProducto::lockForUpdate()->find($detalle->producto_id);
            if ($producto) {
                $stockReal = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle->cantidad;
                
                // Calculamos el faltante exacto bloqueando el registro en el momento del envío
                $cantidadFaltante = max(0, $cantidadSolicitada - $stockReal);
                $cantidadAEntregar = $cantidadSolicitada - $cantidadFaltante;
                
                // Actualizamos permanentemente la cantidad faltante en el detalle del pedido
                $detalle->update(['cantidad_en_produccion' => $cantidadFaltante]);

                if ($cantidadFaltante > 0) {
                    $detallesFaltantes[] = [
                        'producto_id'       => $detalle->producto_id,
                        'pedido_detalle_id' => $detalle->id,
                        'cantidad_faltante' => $cantidadFaltante,
                    ];
                }

                if ($cantidadAEntregar > 0) {
                    $stockResultante = $stockReal - $cantidadAEntregar;
                    $producto->update(['stock' => $stockResultante]);

                    InventarioMovimiento::create([
                        'producto_id'      => $producto->id,
                        'user_id'          => Auth::id(),
                        'tipo'             => 'VENTA',
                        'subtipo'          => 'VENTA A PEDIDO',
                        'cantidad'         => -$cantidadAEntregar,
                        'stock_anterior'   => $stockReal,
                        'stock_resultante' => $stockResultante,
                        'nota'             => "Pedido #{$pedido->id}",
                    ]);
                }
            }
        }

        // Si hubieron faltantes, generamos la Orden de Producción automáticamente
        if (count($detallesFaltantes) > 0) {
            $notaExtra = $pedido->nota_produccion ? "\nNota de vendedor: {$pedido->nota_produccion}" : '';
            $ordenProduccion = \App\Models\OrdenProduccion::create([
                'pedido_id'   => $pedido->id,
                'cliente_id'  => $pedido->cliente_id,
                'vendedor_id' => $pedido->vendedor_id,
                'estado'      => 'pendiente',
                'fecha_estimada_entrega' => $pedido->fecha_entrega,
                'notas'       => "Orden automática generada por faltantes del Pedido #{$pedido->id}{$notaExtra}",
            ]);

            foreach ($detallesFaltantes as $df) {
                $df['orden_produccion_id'] = $ordenProduccion->id;
                \App\Models\OrdenProduccionDetalle::create($df);
            }
        }
    }

    /**
     * Retorna la expresión SQL de año-mes compatible con el driver activo.
     * - SQLite  → strftime('%Y-%m', col)
     * - MySQL   → DATE_FORMAT(col, '%Y-%m')
     * - PgSQL   → TO_CHAR(col, 'YYYY-MM')
     */
    private function _mesFmtExpr(string $columna): string
    {
        return match (DB::getDriverName()) {
            'sqlite' => "strftime('%Y-%m', {$columna})",
            'pgsql'  => "TO_CHAR({$columna}, 'YYYY-MM')",
            default  => "DATE_FORMAT({$columna}, '%Y-%m')",
        };
    }
}
