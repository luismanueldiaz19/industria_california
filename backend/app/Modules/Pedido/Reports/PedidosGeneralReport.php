<?php

namespace App\Modules\Pedido\Reports;

use App\Models\Pedido;
use Barryvdh\DomPDF\Facade\Pdf;

class PedidosGeneralReport implements PdfReportInterface
{
    public function generate(array $params): array
    {
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
                // Si parece un ID (ej: #126 o 126), buscamos por ID
                $num = preg_replace('/[^0-9]/', '', $search);
                if (!empty($num)) {
                    $q->where('id', $num);
                }
                // Y también por nombre de cliente
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

        return ['pdf' => $pdf, 'filename' => $filename];
    }
}
