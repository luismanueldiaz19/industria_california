<?php

namespace App\Modules\Produccion\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Produccion\Models\OrdenProduccion;
use App\Modules\Produccion\Models\OrdenProduccionDetalle;
use App\Modules\Produccion\Services\ProduccionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrdenProduccionController extends Controller
{
    public function __construct(
        private readonly ProduccionService $produccionService
    ) {}
    public function index(Request $request)
    {
        $query = OrdenProduccion::with([
            'cliente:id,nombre',
            'vendedor:id,name',
            'detalles.producto:id,codigo,descripcion,unidad,precio,medidas,capacidad',
        ]);

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        $query->orderBy('created_at', 'desc');
        
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        return response()->json($query->paginate($perPage));
    }

    public function show($id)
    {
        $orden = OrdenProduccion::with([
            'cliente',
            'vendedor',
            'pedido',
            'detalles.producto',
        ])->findOrFail($id);

        return response()->json($orden);
    }

    public function porPedidoId($pedidoId)
    {
        $orden = OrdenProduccion::with([
            'cliente:id,nombre',
            'vendedor:id,name',
            'pedido:id,total,estado',
            'detalles.producto:id,codigo,descripcion,unidad,precio',
        ])->where('pedido_id', $pedidoId)->first();

        if (!$orden) {
            return response()->json(null, 200);
        }

        return response()->json($orden);
    }

    public function marcarDetalleListo($detalleId, Request $request)
    {
        try {
            DB::beginTransaction();

            $detalle = OrdenProduccionDetalle::findOrFail($detalleId);
            
            if ($detalle->estado === 'listo') {
                return response()->json(['message' => 'El detalle ya está listo'], 400);
            }

            // Marcar como listo
            $detalle->update([
                'estado' => 'listo',
                'cantidad_producida' => $detalle->cantidad_faltante
            ]);

            // Si está vinculado a un pedido, descontar la cantidad en producción
            if ($detalle->pedidoDetalle) {
                $pedidoDetalle = $detalle->pedidoDetalle;
                $nuevaCantidad = max(0, $pedidoDetalle->cantidad_en_produccion - $detalle->cantidad_faltante);
                $pedidoDetalle->update(['cantidad_en_produccion' => $nuevaCantidad]);
            }

            // Revisar si todos los detalles de la orden están listos
            $orden = $detalle->ordenProduccion;
            $pendientes = $orden->detalles()->where('estado', 'pendiente')->count();

            if ($pendientes === 0) {
                $orden->update(['estado' => 'lista']);
            } elseif ($orden->estado === 'pendiente') {
                $orden->update(['estado' => 'en_proceso']);
            }

            DB::commit();
            return response()->json(['message' => 'Detalle marcado como listo', 'orden_estado' => $orden->estado]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Error al marcar como listo', 'error' => $e->getMessage()], 500);
        }
    }

    public function generarDesdePedido($pedidoId, Request $request)
    {
        try {
            DB::beginTransaction();

            $pedido = Pedido::with('detalles.producto')->findOrFail($pedidoId);

            // Verificar si ya existe una orden de producción para este pedido
            $ordenExistente = OrdenProduccion::with([
                'cliente:id,nombre',
                'vendedor:id,name',
                'detalles.producto:id,codigo,descripcion,unidad,precio',
            ])->where('pedido_id', $pedidoId)->first();

            if ($ordenExistente) {
                DB::commit();
                return response()->json([
                    'message' => 'Ya existe una orden de producción para este pedido.',
                    'orden' => $ordenExistente,
                ]);
            }

            // Recopilar detalles faltantes
            $detallesFaltantes = [];
            foreach ($pedido->detalles as $det) {
                $cantFaltante = (float) $det->cantidad_en_produccion;

                // Si no estaba explícito, calcular faltante en base a stock
                if ($cantFaltante <= 0 && $det->producto) {
                    $stockReal = (float) $det->producto->stock;
                    $cantFaltante = max(0, (float) $det->cantidad - $stockReal);
                    if ($cantFaltante > 0) {
                        $det->update(['cantidad_en_produccion' => $cantFaltante]);
                    }
                }

                if ($cantFaltante > 0) {
                    $detallesFaltantes[] = [
                        'producto_id'       => $det->producto_id,
                        'pedido_detalle_id' => $det->id,
                        'cantidad_faltante' => $cantFaltante,
                        'cantidad_producida' => 0,
                        'estado'            => 'pendiente',
                    ];
                }
            }

            if (empty($detallesFaltantes)) {
                DB::rollBack();
                return response()->json([
                    'message' => 'El pedido no tiene artículos con faltantes para fabricar.',
                ], 422);
            }

            $nuevaOrden = $this->produccionService->crearOrdenPorFaltantes(
                $pedido->id,
                $pedido->cliente_id,
                $pedido->vendedor_id,
                $detallesFaltantes,
                $request->input('fecha_entrega', $pedido->fecha_entrega),
                $request->input('nota_produccion', $pedido->nota_produccion)
            );

            DB::commit();

            return response()->json([
                'message' => 'Orden de producción generada exitosamente.',
                'orden' => $nuevaOrden->load([
                    'cliente:id,nombre',
                    'vendedor:id,name',
                    'detalles.producto:id,codigo,descripcion,unidad,precio',
                ]),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Error al generar la orden de producción.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
