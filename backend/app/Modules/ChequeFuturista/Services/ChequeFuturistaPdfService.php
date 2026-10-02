<?php

namespace App\Modules\ChequeFuturista\Services;

use App\Modules\ChequeFuturista\Models\ChequeFuturista;
use Barryvdh\DomPDF\Facade\Pdf;

class ChequeFuturistaPdfService
{
    public function renderizarPdf(string $tipo, array $params)
    {
        $query = ChequeFuturista::with(['cliente:id,nombre', 'vendedor:id,name']);
        
        if (!empty($params['id_vendedor'])) {
            $query->where('id_vendedor', $params['id_vendedor']);
        }

        if (!empty($params['buscar'])) {
            $buscar = \App\Helpers\TextNormalizer::normalize($params['buscar']);
            $buscar = preg_replace('/\s+/', ' ', $buscar);
            
            $query->where(function($q) use ($buscar) {
                $q->whereHas('cliente', function ($sub) use ($buscar) {
                    $sub->whereRaw('LOWER(nombre) LIKE ?', ['%' . $buscar . '%']);
                })->orWhereRaw('LOWER(num_cheque) LIKE ?', ['%' . $buscar . '%']);
            });
        }

        if (!empty($params['estado'])) {
            $query->where('estado', $params['estado']);
        }

        $atrasados = filter_var($params['atrasados'] ?? false, FILTER_VALIDATE_BOOLEAN);

        if ($atrasados) {
            $query->where('created_at', '<', now()->subDays(20));
        } elseif (!empty($params['fecha_inicio']) && !empty($params['fecha_fin'])) {
            $query->whereBetween('created_at', [
                $params['fecha_inicio'] . ' 00:00:00', 
                $params['fecha_fin'] . ' 23:59:59'
            ]);
        } else {
            $query->where(function ($q) {
                $q->where('estado', \App\Modules\ChequeFuturista\Enums\EstadoCheque::Pendiente->value)
                  ->orWhere(function ($sub) {
                      $sub->whereMonth('created_at', now()->month)
                          ->whereYear('created_at', now()->year);
                  });
            });
        }

        $cheques = $query->orderByDesc('id')->get();
        $totalMonto = $cheques->sum('monto');
        
        $pdf = Pdf::loadView('pdf.cheques_futuristas_general', [
            'cheques' => $cheques,
            'totalMonto' => $totalMonto,
            'filtros' => $params
        ]);
        
        $filename = 'Cheques_Futuristas_' . date('Ymd') . '.pdf';
        
        return $pdf->stream($filename);
    }
}
