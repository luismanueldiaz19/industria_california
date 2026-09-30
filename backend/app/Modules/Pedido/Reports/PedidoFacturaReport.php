<?php

namespace App\Modules\Pedido\Reports;

use App\Models\Pedido;
use Barryvdh\DomPDF\Facade\Pdf;

class PedidoFacturaReport implements PdfReportInterface
{
    public function generate(array $params): array
    {
        $id = $params['id'] ?? null;
        $pedido = Pedido::with([
            'cliente:id,nombre,direccion,whatsapp,documento', 
            'ruta:id,nombre', 
            'vendedor:id,name', 
            'detalles.producto:id,codigo,descripcion,unidad,medidas,capacidad'
        ])->findOrFail($id);
        
        $pdf = Pdf::loadView('pdf.pedido_factura', compact('pedido'));
        $filename = "pedido_{$pedido->id}.pdf";

        return ['pdf' => $pdf, 'filename' => $filename];
    }
}
