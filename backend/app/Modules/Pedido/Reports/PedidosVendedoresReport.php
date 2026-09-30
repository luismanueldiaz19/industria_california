<?php

namespace App\Modules\Pedido\Reports;

use App\Models\Pedido;
use Barryvdh\DomPDF\Facade\Pdf;

class PedidosVendedoresReport implements PdfReportInterface
{
    public function generate(array $params): array
    {
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

        return ['pdf' => $pdf, 'filename' => $filename];
    }
}
