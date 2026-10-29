<?php

namespace App\Modules\Nomina\Services;

use App\Modules\Nomina\Exports\NominaGeneralExport;
use App\Modules\Nomina\Exports\NominaRecurrentesExport;
use App\Modules\Nomina\Models\Nomina;
use App\Modules\Nomina\Models\NominaEmpleadoRecurrente;
use App\Services\PdfSecurityService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\Response;

class NominaPdfService
{
    /**
     * Resuelve y renderiza de forma segura el reporte o volante de nómina mediante su token opaco.
     */
    public function renderizarPdf(string $tipo, array $params): Response
    {
        switch ($tipo) {
            case 'nomina_volantes':
                return $this->procesarVolantes($params);

            case 'nomina_general':
                return $this->procesarGeneral($params);

            case 'nomina_recurrentes':
                return $this->procesarRecurrentes($params);

            default:
                abort(404, 'Tipo de documento de nómina no reconocido.');
        }
    }

    private function procesarVolantes(array $params): Response
    {
        $nominaId = (int)($params['nomina_id'] ?? 0);
        $nomina = Nomina::with([
            'detalles.empleado',
            'detalles.conceptos.concepto',
        ])->findOrFail($nominaId);

        $detalles = $nomina->detalles;

        if (!empty($params['detalle_id'])) {
            $detalles = $detalles->where('id', (int)$params['detalle_id']);
        } elseif (!empty($params['empleado_id'])) {
            $detalles = $detalles->where('empleado_id', (int)$params['empleado_id']);
        }

        $fechaInicio = $nomina->fecha_inicio ? Carbon::parse($nomina->fecha_inicio)->format('d/m/Y') : '—';
        $fechaFin = $nomina->fecha_fin ? Carbon::parse($nomina->fecha_fin)->format('d/m/Y') : '—';
        $fechaPago = $nomina->fecha_pago ? Carbon::parse($nomina->fecha_pago)->format('d/m/Y') : '—';

        $modo = $params['modo'] ?? 'blade';

        // Generar URLs encriptadas por token para las acciones internas de la barra
        $urlPdf = PdfSecurityService::generarUrl('nomina_volantes', array_merge($params, ['modo' => 'pdf']), auth()->id(), 60);
        $urlExcel = PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'excel'], auth()->id(), 60);

        $data = compact('nomina', 'detalles', 'fechaInicio', 'fechaFin', 'fechaPago', 'urlPdf', 'urlExcel', 'modo');

        if ($modo === 'pdf') {
            $pdf = Pdf::loadView('pdf.nomina_volantes', $data)
                ->setPaper('letter', 'portrait')
                ->setOption('isRemoteEnabled', true);

            return $pdf->stream("Volantes_{$nomina->codigo}.pdf");
        }

        return response()->view('pdf.nomina_volantes', $data);
    }

    private function procesarGeneral(array $params): Response
    {
        $nominaId = (int)($params['nomina_id'] ?? 0);
        $nomina = Nomina::with([
            'detalles.empleado',
            'detalles.conceptos.concepto',
        ])->findOrFail($nominaId);

        $fechaInicio = $nomina->fecha_inicio ? Carbon::parse($nomina->fecha_inicio)->format('d/m/Y') : '—';
        $fechaFin = $nomina->fecha_fin ? Carbon::parse($nomina->fecha_fin)->format('d/m/Y') : '—';
        $fechaPago = $nomina->fecha_pago ? Carbon::parse($nomina->fecha_pago)->format('d/m/Y') : '—';

        $modo = $params['modo'] ?? 'blade';

        if ($modo === 'excel') {
            $filename = "Nomina_{$nomina->codigo}.xlsx";
            return Excel::download(new NominaGeneralExport($nominaId), $filename);
        }

        // Generar URLs encriptadas por token para las acciones internas de la barra
        $urlPdf = PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'pdf'], auth()->id(), 60);
        $urlExcel = PdfSecurityService::generarUrl('nomina_general', ['nomina_id' => $nomina->id, 'modo' => 'excel'], auth()->id(), 60);
        $urlVolantes = PdfSecurityService::generarUrl('nomina_volantes', ['nomina_id' => $nomina->id, 'modo' => 'blade'], auth()->id(), 60);

        $data = compact('nomina', 'fechaInicio', 'fechaFin', 'fechaPago', 'urlPdf', 'urlExcel', 'urlVolantes', 'modo');

        if ($modo === 'pdf') {
            $pdf = Pdf::loadView('pdf.nomina_general', $data)
                ->setPaper('letter', 'landscape')
                ->setOption('isRemoteEnabled', true);

            return $pdf->stream("Reporte_Nomina_{$nomina->codigo}.pdf");
        }

        return response()->view('pdf.nomina_general', $data);
    }

    private function procesarRecurrentes(array $params): Response
    {
        $modo = $params['modo'] ?? 'blade';

        if ($modo === 'excel') {
            $filename = "Cartera_Prestamos_Recurrentes_" . date('Ymd') . ".xlsx";
            return Excel::download(new NominaRecurrentesExport(), $filename);
        }

        $recurrentes = NominaEmpleadoRecurrente::with([
            'empleado',
            'concepto',
        ])->orderBy('id', 'desc')->get();

        $urlPdf = PdfSecurityService::generarUrl('nomina_recurrentes', ['modo' => 'pdf'], auth()->id(), 60);
        $urlExcel = PdfSecurityService::generarUrl('nomina_recurrentes', ['modo' => 'excel'], auth()->id(), 60);

        $data = compact('recurrentes', 'urlPdf', 'urlExcel', 'modo');

        if ($modo === 'pdf') {
            $pdf = Pdf::loadView('pdf.nomina_recurrentes', $data)
                ->setPaper('letter', 'landscape')
                ->setOption('isRemoteEnabled', true);

            return $pdf->stream("Cartera_Prestamos_Recurrentes_" . date('Ymd') . ".pdf");
        }

        return response()->view('pdf.nomina_recurrentes', $data);
    }
}
