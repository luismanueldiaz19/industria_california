<?php

namespace App\Modules\Alerta\Services;

use App\Helpers\TextNormalizer;
use App\Models\User;
use App\Models\LedhouseCxc;
use App\Modules\Alerta\Enums\EstadoAlerta;
use App\Modules\Alerta\Models\Alerta;
use App\Modules\Alerta\Models\AlertaEvidencia;
use App\Services\PdfSecurityService;
use Barryvdh\DomPDF\Facade\Pdf;
use Exception;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AlertaService
{
    /**
     * Construye la consulta base para alertas con sus relaciones y filtros aplicados.
     */
    public function construirQuery(array $filtros = [], ?User $usuario = null): Builder
    {
        $query = Alerta::with([
            'cxc.cliente',
            'cxc.evidencias',
            'vendedor:id,name,email',
            'revisador:id,name,email',
            'evidencias',
        ])->orderByDesc('created_at');

        // Restricción por rol: vendedor solo ve sus propias alertas
        if ($usuario && $usuario->hasRole('vendedor')) {
            $query->where('vendedor_id', $usuario->id);
            if (empty($filtros['start_date']) && empty($filtros['end_date']) && empty($filtros['estado'])) {
                $query->where('estado_alerta', '!=', EstadoAlerta::Procesada->value);
            }
        } elseif (!empty($filtros['vendedor_id'])) {
            $query->where('vendedor_id', $filtros['vendedor_id']);
        }

        // 1. Rango de fechas
        if (!empty($filtros['start_date']) && !empty($filtros['end_date'])) {
            $query->whereBetween('created_at', [
                $filtros['start_date'] . ' 00:00:00',
                $filtros['end_date'] . ' 23:59:59',
            ]);
        }

        // 2. Filtro por Concepto / Tipo
        if (!empty($filtros['tipo']) && $filtros['tipo'] !== 'todos') {
            $query->where('tipo', $filtros['tipo']);
        }

        // 3. Filtro por Estado de Alerta
        if (!empty($filtros['estado']) && $filtros['estado'] !== 'todos') {
            if ($filtros['estado'] === 'pendiente') {
                $query->where('estado_alerta', '!=', EstadoAlerta::Procesada->value);
            } else {
                $query->where('estado_alerta', $filtros['estado']);
            }
        }

        // 4. Búsqueda de texto (normalizada)
        if (!empty($filtros['search']) && trim($filtros['search']) !== '') {
            $search = TextNormalizer::normalize(trim($filtros['search']));

            $query->where(function (Builder $q) use ($search) {
                $q->whereHas('cxc.cliente', function (Builder $q2) use ($search) {
                    $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                       ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                })->orWhereHas('cxc', function (Builder $q3) use ($search) {
                    $q3->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                });
            });
        }

        // 5. Filtro por Cliente
        if (!empty($filtros['cliente_id'])) {
            $query->whereHas('cxc', function (Builder $q) use ($filtros) {
                $q->where('cliente_id', $filtros['cliente_id']);
            });
        }

        return $query;
    }

    /**
     * Lista alertas aplicando filtros y paginación opcional.
     */
    public function listar(array $filtros = [], ?User $usuario = null): LengthAwarePaginator|Collection
    {
        $query = $this->construirQuery($filtros, $usuario);

        $shouldPaginate = !empty($filtros['paginate']) || !empty($filtros['page']) || !empty($filtros['limit']);

        if ($shouldPaginate) {
            $perPage = (int) ($filtros['limit'] ?? $filtros['per_page'] ?? 20);
            return $query->paginate($perPage);
        }

        return $query->get();
    }

    /**
     * Registra una nueva alerta asociada a un documento CXC.
     */
    public function crear(array $datos, User $usuario): Alerta
    {
        $cxc = LedhouseCxc::findOrFail($datos['ledhouse_cxc_id']);

        if ($usuario->hasRole('vendedor') && (int) $cxc->vendedor_id !== (int) $usuario->id) {
            throw new Exception('No tienes permiso para alertar este documento.');
        }

        return DB::transaction(function () use ($datos, $usuario, $cxc) {
            $alerta = Alerta::create([
                'ledhouse_cxc_id' => $cxc->id,
                'vendedor_id'     => $usuario->id,
                'tipo'            => $datos['tipo'],
                'monto_informado' => $datos['monto_informado'] ?? null,
                'nota'            => $datos['nota'],
                'estado_alerta'   => EstadoAlerta::Pendiente,
            ]);

            // Vincular cualquier evidencia previa de este CXC sin alerta asignada
            AlertaEvidencia::where('ledhouse_cxc_id', $cxc->id)
                ->whereNull('alerta_id')
                ->update(['alerta_id' => $alerta->id]);

            return $alerta->load(['vendedor:id,name,email', 'cxc.cliente', 'cxc.evidencias', 'evidencias']);
        });
    }

    /**
     * Resuelve/procesa una alerta con la regla automática de negocio:
     * Si el monto pagado reportado es mayor o igual al saldo pendiente de la CXC,
     * la cuenta por cobrar se marca automáticamente en estado 'pagado'.
     */
    public function resolver(int|Alerta $alerta, array $datos, User $revisor): Alerta
    {
        if (is_int($alerta)) {
            $alerta = Alerta::with('cxc')->findOrFail($alerta);
        }

        return DB::transaction(function () use ($alerta, $datos, $revisor) {
            $alerta->update([
                'estado_alerta'  => $datos['estado_alerta'],
                'revisada_por'   => $revisor->id,
                'fecha_revision' => now(),
            ]);

            // Actualizar CXC si se solicita y existe
            if (!empty($datos['actualizar_cxc']) && $alerta->cxc) {
                $cxc = $alerta->cxc;
                $updates = [];

                if (isset($datos['monto_pagado'])) {
                    $pago = (float) $datos['monto_pagado'];
                    $saldoPendiente = (float) $cxc->monto_pendiente;
                    $nuevoPendiente = max(0, (float) $cxc->monto_factura - $pago);

                    $updates['monto_pagado']    = $pago;
                    $updates['monto_pendiente'] = $nuevoPendiente;

                    // REGLA CLAVE: si el pago cubre el saldo pendiente (o el saldo restante llega a 0),
                    // marcar automáticamente como pagado para evitar omisiones humanas.
                    if (round($pago, 2) >= round($saldoPendiente, 2) || $nuevoPendiente <= 0.0001) {
                        $updates['estado'] = 'pagado';
                    }
                }

                if (isset($datos['estado_cxc'])) {
                    if (!isset($updates['estado'])) {
                        $updates['estado'] = $datos['estado_cxc'];
                    } elseif ($datos['estado_cxc'] === 'cancelado') {
                        $updates['estado'] = 'cancelado';
                    }
                }

                if (!empty($updates)) {
                    $cxc->update($updates);
                }
            }

            return $alerta->fresh(['cxc.cliente', 'vendedor:id,name', 'revisador:id,name', 'evidencias']);
        });
    }

    /**
     * Actualiza el concepto/tipo de una alerta existente.
     */
    public function actualizarTipo(int|Alerta $alerta, string $nuevoTipo): Alerta
    {
        if (is_int($alerta)) {
            $alerta = Alerta::findOrFail($alerta);
        }

        $alerta->update(['tipo' => $nuevoTipo]);

        return $alerta->fresh(['cxc.cliente', 'vendedor:id,name', 'revisador:id,name']);
    }

    /**
     * Elimina una alerta y limpia todos los archivos físicos asociados.
     */
    public function eliminar(int|Alerta $alerta, User $usuario): void
    {
        if (is_int($alerta)) {
            $alerta = Alerta::findOrFail($alerta);
        }

        if ($usuario->hasRole('vendedor') && (int) $alerta->vendedor_id !== (int) $usuario->id) {
            throw new Exception('No tienes permiso para eliminar esta alerta.');
        }

        DB::transaction(function () use ($alerta) {
            $evidencias = AlertaEvidencia::where('alerta_id', $alerta->id)
                ->orWhere(function ($query) use ($alerta) {
                    $query->where('ledhouse_cxc_id', $alerta->ledhouse_cxc_id)
                          ->whereNull('alerta_id');
                })->get();

            foreach ($evidencias as $ev) {
                if ($ev->ruta_archivo && Storage::disk('public')->exists($ev->ruta_archivo)) {
                    Storage::disk('public')->delete($ev->ruta_archivo);
                }
                $ev->delete();
            }

            $alerta->delete();
        });
    }

    /**
     * Devuelve métricas y resumen de alertas para dashboards o cabeceras.
     */
    public function resumen(?User $usuario = null): array
    {
        $query = Alerta::query();

        if ($usuario && $usuario->hasRole('vendedor')) {
            $query->where('vendedor_id', $usuario->id);
        }

        $totalAlertas = (clone $query)->count();
        $pendientes = (clone $query)->where('estado_alerta', '!=', EstadoAlerta::Procesada->value)->count();
        $procesadas = (clone $query)->where('estado_alerta', EstadoAlerta::Procesada->value)->count();
        $totalInformado = (clone $query)->sum('monto_informado');
        $montoPendientes = (clone $query)->where('estado_alerta', '!=', EstadoAlerta::Procesada->value)->sum('monto_informado');

        return [
            'total_alertas'           => $totalAlertas,
            'pendientes_count'        => $pendientes,
            'procesadas_count'        => $procesadas,
            'total_monto_informado'   => (float) $totalInformado,
            'monto_pendientes'        => (float) $montoPendientes,
        ];
    }

    /**
     * Genera el Stream PDF del reporte de alertas.
     */
    public function generarPdf(array $filtros, ?User $usuario)
    {
        $query = $this->construirQuery($filtros, $usuario);
        $alertas = $query->get();

        $totalInformado = $alertas->sum('monto_informado');

        $cxcQuery = LedhouseCxc::query();
        if ($usuario && $usuario->hasRole('vendedor')) {
            $cxcQuery->where('vendedor_id', $usuario->id);
        } elseif (!empty($filtros['vendedor_id'])) {
            $cxcQuery->where('vendedor_id', $filtros['vendedor_id']);
        }
        if (!empty($filtros['cliente_id'])) {
            $cxcQuery->where('cliente_id', $filtros['cliente_id']);
        }

        $totalPendiente = $cxcQuery->sum('monto_pendiente');
        $montoReal = $totalPendiente - $totalInformado;

        $pdf = Pdf::loadView('pdf.alertas_vendedores', [
            'alertas'        => $alertas,
            'totalInformado' => $totalInformado,
            'totalPendiente' => $totalPendiente,
            'montoReal'      => $montoReal,
            'estado'         => $filtros['estado'] ?? 'todas',
        ])->setPaper('a4', 'landscape');

        return $pdf->stream('Reporte_Alertas_' . date('Ymd_His') . '.pdf');
    }

    /**
     * Genera una URL segura temporal para previsualizar/descargar el PDF.
     */
    public function obtenerPdfUrl(array $filtros, ?User $usuario): string
    {
        return PdfSecurityService::generarUrl(
            'cxc_alertas',
            [
                'estado'      => $filtros['estado'] ?? 'todas',
                'vendedor_id' => $filtros['vendedor_id'] ?? null,
                'cliente_id'  => $filtros['cliente_id'] ?? null,
                'start_date'  => $filtros['start_date'] ?? null,
                'end_date'    => $filtros['end_date'] ?? null,
                'tipo'        => $filtros['tipo'] ?? null,
                'search'      => $filtros['search'] ?? null,
            ],
            $usuario?->id,
            minutos: 30
        );
    }

    /**
     * Sube y registra una evidencia para un documento CXC y/o una alerta.
     */
    public function subirEvidencia(int|LedhouseCxc $cxc, $file, User $usuario, ?int $alertaId = null): AlertaEvidencia
    {
        $cxcId = is_int($cxc) ? $cxc : $cxc->id;
        $cxcModel = is_int($cxc) ? LedhouseCxc::findOrFail($cxc) : $cxc;

        if ($usuario->hasRole('vendedor') && (int) $cxcModel->vendedor_id !== (int) $usuario->id) {
            throw new Exception('No tienes permiso para subir evidencias a este documento.');
        }

        // Si no se proporcionó alertaId, asociarlo a la alerta más reciente de este CXC
        if (!$alertaId) {
            $latestAlerta = Alerta::where('ledhouse_cxc_id', $cxcId)->latest()->first();
            if ($latestAlerta) {
                $alertaId = $latestAlerta->id;
            }
        }

        $ext = strtolower($file->getClientOriginalExtension());
        $path = $file->store("cxc-evidencias/{$cxcId}", 'public');

        return AlertaEvidencia::create([
            'ledhouse_cxc_id' => $cxcId,
            'alerta_id'       => $alertaId,
            'subido_por'      => $usuario->id,
            'nombre_archivo'  => $file->getClientOriginalName(),
            'ruta_archivo'    => $path,
            'tipo_archivo'    => $ext,
        ])->load('subidor:id,name');
    }

    /**
     * Lista las evidencias de un documento CXC.
     */
    public function listarEvidencias(int $cxcId): Collection
    {
        return AlertaEvidencia::where('ledhouse_cxc_id', $cxcId)
            ->with('subidor:id,name')
            ->orderByDesc('created_at')
            ->get();
    }
}
