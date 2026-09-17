<?php

namespace App\Modules\Produccion\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Produccion\Models\OrdenProduccion;
use App\Modules\Produccion\Models\OrdenProduccionDetalle;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrdenProduccionController extends Controller
{
    public function index(Request $request)
    {
        $query = OrdenProduccion::with([
            'cliente:id,nombre',
            'vendedor:id,name',
            'detalles.producto:id,codigo,descripcion as nombre,unidad',
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
}
