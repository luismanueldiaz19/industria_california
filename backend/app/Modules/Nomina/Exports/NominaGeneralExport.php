<?php

namespace App\Modules\Nomina\Exports;

use App\Modules\Nomina\Models\Nomina;
use Carbon\Carbon;
use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class NominaGeneralExport implements FromView, ShouldAutoSize, WithTitle
{
    protected int $nominaId;

    public function __construct(int $nominaId)
    {
        $this->nominaId = $nominaId;
    }

    public function view(): View
    {
        $nomina = Nomina::with([
            'detalles.empleado',
            'detalles.conceptos.concepto',
        ])->findOrFail($this->nominaId);

        $fechaInicio = $nomina->fecha_inicio ? Carbon::parse($nomina->fecha_inicio)->format('d/m/Y') : '—';
        $fechaFin = $nomina->fecha_fin ? Carbon::parse($nomina->fecha_fin)->format('d/m/Y') : '—';
        $fechaPago = $nomina->fecha_pago ? Carbon::parse($nomina->fecha_pago)->format('d/m/Y') : '—';

        return view('exports.nomina_general_excel', compact('nomina', 'fechaInicio', 'fechaFin', 'fechaPago'));
    }

    public function title(): string
    {
        return 'Nómina General';
    }
}

