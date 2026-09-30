<?php

namespace App\Modules\Pedido\Services;

use App\Models\Pedido;
use Barryvdh\DomPDF\Facade\Pdf;
use Symfony\Component\HttpFoundation\Response;

class PedidoPdfService
{
    /**
     * Renderiza los PDFs correspondientes al módulo de Pedidos.
     */
    public function renderizarPdf(string $tipo, array $params): Response
    {
        switch ($tipo) {
            case 'pedidos_general':
                $query = Pedido::with([
                    'cliente:id,nombre',
                    'vendedor:id,name',
                    'detalles'
                ]);
                
                if (!empty($params['cliente_id'])) {
                    $query->where('cliente_id', $params['cliente_id']);
                }
                
                if (!empty($params['search'])) {
                    $search = $params['search'];
                    $query->where(function ($q) use ($search) {
                        $num = preg_replace('/[^0-9]/', '', $search);
                        if (!empty($num)) {
                            $q->where('id', $num);
                        }
                        $q->orWhereHas('cliente', function ($q2) use ($search) {
                            $q2->whereRaw('LOWER(nombre) LIKE ?', ['%' . mb_strtolower($search) . '%']);
                        });
                    });
                }
                if (!empty($params['ruta_id'])) {
                    $query->where('ruta_id', $params['ruta_id']);
                }
                if (!empty($params['estado'])) {
                    $query->where('estado', $params['estado']);
                }
                if (!empty($params['start_date']) || !empty($params['end_date'])) {
                    if (!empty($params['start_date'])) {
                        $query->whereDate('created_at', '>=', $params['start_date']);
                    }
                    if (!empty($params['end_date'])) {
                        $query->whereDate('created_at', '<=', $params['end_date']);
                    }
                } else {
                    $query->where(function ($q) {
                        $q->whereDate('created_at', now()->toDateString())
                          ->orWhereIn('estado', ['borrador', 'enviado']);
                    });
                }
                
                if (!empty($params['vendedor_id'])) {
                    $query->where('vendedor_id', $params['vendedor_id']);
                }

                if (!empty($params['has_faltantes']) && ($params['has_faltantes'] == '1' || $params['has_faltantes'] == 'true')) {
                    $query->whereHas('detalles', function ($q) {
                        $q->where('cantidad_en_produccion', '>', 0);
                    });
                }

                $pedidos = $query->orderBy('created_at', 'desc')->get();
                
                $pdf = Pdf::loadView('pdf.pedidos_general', [
                    'pedidos' => $pedidos,
                    'fechaInicio' => $params['start_date'] ?? null,
                    'fechaFin' => $params['end_date'] ?? null,
                ]);
                $filename = 'Reporte_General_Pedidos_' . date('Ymd_His') . '.pdf';
                break;

            case 'pedido':
                $id = $params['id'] ?? null;
                $pedido = Pedido::with([
                    'cliente:id,nombre,direccion,whatsapp,documento', 
                    'ruta:id,nombre', 
                    'vendedor:id,name', 
                    'detalles.producto:id,codigo,descripcion,unidad,medidas,capacidad'
                ])->findOrFail($id);
                $pdf = Pdf::loadView('pdf.pedido_factura', compact('pedido'));
                $filename = "pedido_{$pedido->id}.pdf";
                break;

            case 'pedidos_vendedores':
                // ── Scope base usando el modelo Pedido + relación vendedor ──
                $baseScope = Pedido::query()
                    ->with(['vendedor:id,name', 'cliente:id,nombre'])
                    ->when(!empty($params['start_date']),
                        fn($q) => $q->whereDate('created_at', '>=', $params['start_date'])
                    )
                    ->when(!empty($params['end_date']),
                        fn($q) => $q->whereDate('created_at', '<=', $params['end_date'])
                    )
                    ->when(!empty($params['vendedor_id']),
                        fn($q) => $q->where('vendedor_id', $params['vendedor_id'])
                    )
                    ->when(!empty($params['search']),
                        fn($q) => $q->whereHas('vendedor', fn($vq) =>
                            $vq->whereRaw('LOWER(name) LIKE ?', [
                                '%' . mb_strtolower($params['search']) . '%'
                            ])
                        )
                    );

                // ── Agrupar totales por vendedor con Eloquent ──
                $grupos = (clone $baseScope)
                    ->selectRaw(
                        "vendedor_id,
                        COUNT(id) as total_pedidos,
                        SUM(total) as total_monto,
                        SUM(CASE WHEN estado = 'borrador'  THEN 1 ELSE 0 END) as borrador,
                        SUM(CASE WHEN estado = 'enviado'   THEN 1 ELSE 0 END) as enviado,
                        SUM(CASE WHEN estado = 'facturado' THEN 1 ELSE 0 END) as facturado,
                        SUM(CASE WHEN estado = 'cancelado' THEN 1 ELSE 0 END) as cancelado"
                    )
                    ->with('vendedor:id,name')
                    ->groupBy('vendedor_id')
                    ->orderByDesc('total_monto')
                    ->get();

                // ── Construir la colección de datos para la vista ──
                $vendedoresData = $grupos
                    ->filter(fn($g) => $g->vendedor !== null)
                    ->map(fn($g) => [
                        'vendedor_nombre' => $g->vendedor->name,
                        'total_pedidos'   => (int)   $g->total_pedidos,
                        'total_monto'     => (float) $g->total_monto,
                        'borrador'        => (int)   $g->borrador,
                        'enviado'         => (int)   $g->enviado,
                        'facturado'       => (int)   $g->facturado,
                        'cancelado'       => (int)   $g->cancelado,
                        // Pedidos individuales del vendedor en el período
                        'pedidos' => (clone $baseScope)
                            ->where('vendedor_id', $g->vendedor_id)
                            ->orderByDesc('created_at')
                            ->get(),
                    ])
                    ->values()
                    ->all();

                $pdf = Pdf::loadView('pdf.pedidos_vendedores', [
                    'vendedores'  => $vendedoresData,
                    'fechaInicio' => $params['start_date'] ?? null,
                    'fechaFin'    => $params['end_date']   ?? null,
                ])->setPaper('a4', 'landscape');
                $filename = 'Reporte_Vendedores_Pedidos_' . date('Ymd_His') . '.pdf';
                break;

            default:
                abort(404, 'Tipo de documento de pedido no soportado.');
        }

        $headers = [
            'Content-Type'           => 'application/pdf',
            'Content-Disposition'    => 'inline; filename="' . $filename . '"',
            'Cache-Control'          => 'private, no-cache, no-store, must-revalidate',
            'Pragma'                 => 'no-cache',
            'Expires'                => '0',
            'X-Content-Type-Options' => 'nosniff',
        ];

        return response($pdf->output(), 200, $headers);
    }
}
