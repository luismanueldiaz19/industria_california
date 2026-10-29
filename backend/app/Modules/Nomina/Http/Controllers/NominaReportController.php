<?php

namespace App\Modules\Nomina\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Nomina\Exports\NominaGeneralExport;
use App\Modules\Nomina\Exports\NominaRecurrentesExport;
use App\Modules\Nomina\Models\Nomina;
use App\Modules\Nomina\Models\NominaEmpleadoRecurrente;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class NominaReportController extends Controller
{
    /**
     * Muestra la vista Blade con todos los volantes de pago de la nómina (o uno individual).
     */
    public function imprimirVolantes(Request $request, int $nominaId)
    {
        $data = $this->prepararDatosVolantes($request, $nominaId);
        return view('pdf.nomina_volantes', $data);
    }

    /**
     * Descarga o visualiza en stream el PDF de los volantes de pago con DomPDF.
     */
    public function descargarPdfVolantes(Request $request, int $nominaId)
    {
        $data = $this->prepararDatosVolantes($request, $nominaId);
        $codigo = $data['nomina']->codigo;

        $pdf = Pdf::loadView('pdf.nomina_volantes', $data)
            ->setPaper('letter', 'portrait')
            ->setOption('isRemoteEnabled', true);

        return $pdf->stream("Volantes_{$codigo}.pdf");
    }

    /**
     * Muestra la vista Blade del reporte general de nómina apaisado en navegador.
     */
    public function imprimirGeneral(Request $request, int $nominaId)
    {
        $data = $this->prepararDatosGeneral($nominaId);
        return view('pdf.nomina_general', $data);
    }

    /**
     * Descarga o visualiza en stream el PDF del reporte general de nómina.
     */
    public function descargarPdfGeneral(Request $request, int $nominaId)
    {
        $data = $this->prepararDatosGeneral($nominaId);
        $codigo = $data['nomina']->codigo;

        $pdf = Pdf::loadView('pdf.nomina_general', $data)
            ->setPaper('letter', 'landscape')
            ->setOption('isRemoteEnabled', true);

        return $pdf->stream("Reporte_Nomina_{$codigo}.pdf");
    }

    /**
     * Descarga el archivo Excel estructurado (.xlsx) de la nómina general.
     */
    public function descargarExcelGeneral(Request $request, int $nominaId)
    {
        $nomina = Nomina::findOrFail($nominaId);
        $filename = "Nomina_{$nomina->codigo}.xlsx";

        return Excel::download(new NominaGeneralExport($nominaId), $filename);
    }

    /**
     * Muestra la vista Blade del reporte de préstamos y descuentos recurrentes.
     */
    public function imprimirRecurrentes(Request $request)
    {
        $recurrentes = NominaEmpleadoRecurrente::with([
            'empleado',
            'concepto',
        ])->orderBy('id', 'desc')->get();

        return view('pdf.nomina_recurrentes', compact('recurrentes'));
    }

    /**
     * Descarga o visualiza en stream el PDF del reporte de préstamos recurrentes.
     */
    public function descargarPdfRecurrentes(Request $request)
    {
        $recurrentes = NominaEmpleadoRecurrente::with([
            'empleado',
            'concepto',
        ])->orderBy('id', 'desc')->get();

        $pdf = Pdf::loadView('pdf.nomina_recurrentes', compact('recurrentes'))
            ->setPaper('letter', 'landscape')
            ->setOption('isRemoteEnabled', true);

        return $pdf->stream("Cartera_Prestamos_Recurrentes_" . date('Ymd') . ".pdf");
    }

    /**
     * Descarga el archivo Excel estructurado (.xlsx) de la cartera de préstamos.
     */
    public function descargarExcelRecurrentes(Request $request)
    {
        $filename = "Cartera_Prestamos_Recurrentes_" . date('Ymd') . ".xlsx";
        return Excel::download(new NominaRecurrentesExport(), $filename);
    }

    // ── Helper Privados ──────────────────────────────────────────────

    private function prepararDatosVolantes(Request $request, int $nominaId): array
    {
        $nomina = Nomina::with([
            'detalles.empleado',
            'detalles.conceptos.concepto',
        ])->findOrFail($nominaId);

        $detalles = $nomina->detalles;

        // Filtro opcional por detalle específico (volante individual)
        if ($request->has('detalle_id')) {
            $detalles = $detalles->where('id', (int)$request->get('detalle_id'));
        } elseif ($request->has('empleado_id')) {
            $detalles = $detalles->where('empleado_id', (int)$request->get('empleado_id'));
        }

        $fechaInicio = $nomina->fecha_inicio ? Carbon::parse($nomina->fecha_inicio)->format('d/m/Y') : '—';
        $fechaFin = $nomina->fecha_fin ? Carbon::parse($nomina->fecha_fin)->format('d/m/Y') : '—';
        $fechaPago = $nomina->fecha_pago ? Carbon::parse($nomina->fecha_pago)->format('d/m/Y') : '—';

        return compact('nomina', 'detalles', 'fechaInicio', 'fechaFin', 'fechaPago');
    }

    private function prepararDatosGeneral(int $nominaId): array
    {
        $nomina = Nomina::with([
            'detalles.empleado',
            'detalles.conceptos.concepto',
        ])->findOrFail($nominaId);

        $fechaInicio = $nomina->fecha_inicio ? Carbon::parse($nomina->fecha_inicio)->format('d/m/Y') : '—';
        $fechaFin = $nomina->fecha_fin ? Carbon::parse($nomina->fecha_fin)->format('d/m/Y') : '—';
        $fechaPago = $nomina->fecha_pago ? Carbon::parse($nomina->fecha_pago)->format('d/m/Y') : '—';

        return compact('nomina', 'fechaInicio', 'fechaFin', 'fechaPago');
    }
}

