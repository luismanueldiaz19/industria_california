<?php

namespace App\Modules\Nomina\Exports;

use App\Modules\Nomina\Models\NominaEmpleadoRecurrente;
use Illuminate\Contracts\View\View;
use Maatwebsite\Excel\Concerns\FromView;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithTitle;

class NominaRecurrentesExport implements FromView, ShouldAutoSize, WithTitle
{
    public function view(): View
    {
        $recurrentes = NominaEmpleadoRecurrente::with([
            'empleado',
            'concepto',
        ])->orderBy('id', 'desc')->get();

        return view('exports.nomina_recurrentes_excel', compact('recurrentes'));
    }

    public function title(): string
    {
        return 'Préstamos Recurrentes';
    }
}

