<?php

namespace App\Modules\Produccion\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface;

class ProduccionAgrupadaController extends Controller
{
    public function __construct(
        private readonly ProduccionRepositoryInterface $produccionRepository
    ) {}

    public function marcarListoAgrupadoProducto(Request $request)
    {
        $request->validate([
            'producto_id' => 'required|integer',
            'cliente_id' => 'required|integer',
        ]);

        try {
            \Illuminate\Support\Facades\DB::beginTransaction();

            $detalles = \App\Modules\Produccion\Models\OrdenProduccionDetalle::where('producto_id', $request->producto_id)
                ->where('estado', 'pendiente')
                ->whereHas('ordenProduccion', function($q) use ($request) {
                    $q->where('estado', '!=', 'lista')
                      ->where('cliente_id', $request->cliente_id);
                })
                ->get();

            if ($detalles->isEmpty()) {
                return response()->json(['message' => 'No se encontraron detalles pendientes'], 404);
            }

            foreach ($detalles as $detalle) {
                $detalle->update([
                    'estado' => 'listo',
                    'cantidad_producida' => $detalle->cantidad_faltante
                ]);

                if ($detalle->pedidoDetalle) {
                    $pedidoDetalle = $detalle->pedidoDetalle;
                    $nuevaCantidad = max(0, $pedidoDetalle->cantidad_en_produccion - $detalle->cantidad_faltante);
                    $pedidoDetalle->update(['cantidad_en_produccion' => $nuevaCantidad]);
                }

                $orden = $detalle->ordenProduccion;
                $pendientes = $orden->detalles()->where('estado', 'pendiente')->count();

                if ($pendientes === 0) {
                    $orden->update(['estado' => 'lista']);
                } elseif ($orden->estado === 'pendiente') {
                    $orden->update(['estado' => 'en_proceso']);
                }
            }

            \Illuminate\Support\Facades\DB::commit();
            return response()->json(['message' => 'Producción marcada como lista correctamente.']);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\DB::rollBack();
            return response()->json(['message' => 'Error al marcar como listo', 'error' => $e->getMessage()], 500);
        }
    }

    public function getPdfUrl(Request $request)
    {
        $tipo = $request->input('tipo', 'producto');
        $params = ['tipo' => $tipo];

        if ($request->has('search') && !empty($request->input('search'))) {
            $params['search'] = $request->input('search');
        }

        $url = \App\Services\PdfSecurityService::generarUrl('produccion_agrupada', $params, $request->user()->id ?? null);
        return response()->json(['url' => $url]);
    }

    public function porProducto(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorProducto($perPage, $search);

        return response()->json($resultados);
    }

    public function porPedido(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorPedido($perPage, $search);

        return response()->json($resultados);
    }

    public function porCliente(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $resultados = $this->produccionRepository->getAgrupadoPorCliente($perPage, $search);

        return response()->json($resultados);
    }

    public function porFecha(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');
        
        $resultados = $this->produccionRepository->getAgrupadoPorFecha($perPage, $search);

        return response()->json($resultados);
    }
}
