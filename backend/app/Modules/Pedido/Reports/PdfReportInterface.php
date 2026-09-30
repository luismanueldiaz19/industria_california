<?php

namespace App\Modules\Pedido\Reports;

interface PdfReportInterface
{
    /**
     * Genera la vista PDF y el nombre del archivo.
     * Retorna un array con ['pdf' => $pdf, 'filename' => $filename]
     */
    public function generate(array $params): array;
}
