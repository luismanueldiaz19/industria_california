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
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

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
            'grupoAlertas:id,grupo_pago_id,ledhouse_cxc_id,monto_informado,estado_alerta',
            'grupoAlertas.cxc:id,documento,monto_factura,monto_pendiente,estado',
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
     * Registra un PAGO AGRUPADO: un único comprobante que cubre varias facturas.
     *
     * - Crea una alerta por cada factura (con su propio monto_informado).
     * - Todas comparten el mismo grupo_pago_id.
     * - El archivo se guarda UNA sola vez y se crea un registro de evidencia por alerta
     *   apuntando a la misma ruta física.
     *
     * @param array $datos ['tipo', 'nota', 'monto_total', 'items' => [['cxc_id', 'monto'], ...]]
     */
    public function crearLote(array $datos, UploadedFile $file, User $usuario): Collection
    {
        $items = collect($datos['items'] ?? [])->map(fn ($i) => [
            'cxc_id' => (int) $i['cxc_id'],
            'monto'  => round((float) $i['monto'], 2),
        ])->values();

        if ($items->count() < 2) {
            throw new Exception('Un pago agrupado debe incluir al menos 2 facturas.');
        }

        if ($items->pluck('cxc_id')->unique()->count() !== $items->count()) {
            throw new Exception('Hay facturas repetidas en el pago agrupado.');
        }

        $cxcs = LedhouseCxc::whereIn('id', $items->pluck('cxc_id'))->get()->keyBy('id');

        if ($cxcs->count() !== $items->count()) {
            throw new Exception('Una o más facturas seleccionadas no existen.');
        }

        if ($cxcs->pluck('cliente_id')->unique()->count() > 1) {
            throw new Exception('Todas las facturas de un pago agrupado deben ser del mismo cliente.');
        }

        foreach ($items as $item) {
            $cxc = $cxcs[$item['cxc_id']];

            if ($usuario->hasRole('vendedor') && (int) $cxc->vendedor_id !== (int) $usuario->id) {
                throw new Exception("No tienes permiso para alertar el documento {$cxc->documento}.");
            }

            if ($cxc->estado === 'pagado') {
                throw new Exception("La factura {$cxc->documento} ya está pagada.");
            }

            if ($item['monto'] <= 0) {
                throw new Exception("El monto asignado a {$cxc->documento} debe ser mayor que cero.");
            }

            if ($item['monto'] - (float) $cxc->monto_pendiente > 0.01) {
                throw new Exception(sprintf(
                    'El monto asignado a %s ($%s) supera su saldo pendiente ($%s).',
                    $cxc->documento,
                    number_format($item['monto'], 2),
                    number_format((float) $cxc->monto_pendiente, 2)
                ));
            }
        }

        $total = round((float) $datos['monto_total'], 2);
        $suma  = round($items->sum('monto'), 2);

        if (abs($suma - $total) > 0.01) {
            throw new Exception(sprintf(
                'La suma repartida ($%s) no coincide con el monto total del pago ($%s).',
                number_format($suma, 2),
                number_format($total, 2)
            ));
        }

        $grupoId = (string) Str::uuid();
        $ext     = strtolower($file->getClientOriginalExtension());
        $nombre  = $file->getClientOriginalName();
        $path    = $file->store("cxc-evidencias/grupos/{$grupoId}", 'public');

        $documentos = $items->map(fn ($i) => $cxcs[$i['cxc_id']]->documento)->implode(', ');
        $nota = trim($datos['nota']) . "\n" . sprintf(
            '[Pago agrupado: %d facturas (%s) · Total $%s]',
            $items->count(),
            $documentos,
            number_format($total, 2)
        );

        try {
            $ids = DB::transaction(function () use ($items, $grupoId, $usuario, $datos, $nota, $path, $nombre, $ext) {
                $ids = [];

                foreach ($items as $item) {
                    $alerta = Alerta::create([
                        'ledhouse_cxc_id' => $item['cxc_id'],
                        'vendedor_id'     => $usuario->id,
                        'grupo_pago_id'   => $grupoId,
                        'tipo'            => $datos['tipo'],
                        'monto_informado' => $item['monto'],
                        'nota'            => $nota,
                        'estado_alerta'   => EstadoAlerta::Pendiente,
                    ]);

                    AlertaEvidencia::create([
                        'ledhouse_cxc_id' => $item['cxc_id'],
                        'alerta_id'       => $alerta->id,
                        'grupo_pago_id'   => $grupoId,
                        'subido_por'      => $usuario->id,
                        'nombre_archivo'  => $nombre,
                        'ruta_archivo'    => $path,
                        'tipo_archivo'    => $ext,
                    ]);

                    $ids[] = $alerta->id;
                }

                return $ids;
            });
        } catch (Throwable $e) {
            // Si falla la BD, no dejar el archivo huérfano en disco
            Storage::disk('public')->delete($path);
            throw $e;
        }

        return Alerta::with([
            'vendedor:id,name,email',
            'cxc.cliente',
            'evidencias',
            'grupoAlertas:id,grupo_pago_id,ledhouse_cxc_id,monto_informado,estado_alerta',
            'grupoAlertas.cxc:id,documento,monto_factura,monto_pendiente,estado',
        ])->whereIn('id', $ids)->get();
    }

    /**
     * Procesa todas las alertas pendientes de un pago agrupado en una sola operación.
     *
     * El monto de cada factura se toma de $datos['items'] (alerta_id => monto_pagado)
     * o, si no se envía, del monto_informado por el vendedor. El monto se aplica como
     * ABONO (se suma a lo ya pagado y se resta del pendiente).
     */
    public function resolverGrupo(string $grupoId, array $datos, User $revisor): Collection
    {
        $alertas = Alerta::with('cxc')->where('grupo_pago_id', $grupoId)->get();

        if ($alertas->isEmpty()) {
            throw new Exception('El pago agrupado no existe.');
        }

        $montos = collect($datos['items'] ?? [])->mapWithKeys(fn ($i) => [
            (int) $i['alerta_id'] => round((float) $i['monto_pagado'], 2),
        ]);

        $actualizarCxc = !empty($datos['actualizar_cxc']);

        DB::transaction(function () use ($alertas, $datos, $revisor, $montos, $actualizarCxc) {
            foreach ($alertas as $alerta) {
                if ($alerta->isProcesada()) {
                    continue;
                }

                $alerta->update([
                    'estado_alerta'  => $datos['estado_alerta'],
                    'revisada_por'   => $revisor->id,
                    'fecha_revision' => now(),
                ]);

                if ($actualizarCxc && $alerta->cxc) {
                    $abono = $montos[$alerta->id] ?? (float) $alerta->monto_informado;
                    if ($abono > 0) {
                        $this->aplicarAbono($alerta->cxc, $abono);
                    }
                }
            }
        });

        return Alerta::with([
            'cxc.cliente',
            'vendedor:id,name',
            'revisador:id,name',
            'evidencias',
            'grupoAlertas:id,grupo_pago_id,ledhouse_cxc_id,monto_informado,estado_alerta',
            'grupoAlertas.cxc:id,documento,monto_factura,monto_pendiente,estado',
        ])->where('grupo_pago_id', $grupoId)->get();
    }

    /**
     * Aplica un abono a una CXC: suma a lo pagado, resta del pendiente y marca
     * como 'pagado' automáticamente cuando el saldo llega a cero.
     */
    private function aplicarAbono(LedhouseCxc $cxc, float $abono): void
    {
        $pendienteActual = (float) $cxc->monto_pendiente;
        $abonoReal       = min($abono, $pendienteActual);
        $nuevoPendiente  = max(0, round($pendienteActual - $abonoReal, 2));

        $updates = [
            'monto_pagado'    => round((float) $cxc->monto_pagado + $abonoReal, 2),
            'monto_pendiente' => $nuevoPendiente,
        ];

        if ($nuevoPendiente <= 0.0001) {
            $updates['estado'] = 'pagado';
        }

        $cxc->update($updates);
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

            $rutas = $evidencias->pluck('ruta_archivo')->filter()->unique();

            AlertaEvidencia::whereIn('id', $evidencias->pluck('id'))->delete();
            $alerta->delete();

            // Solo borrar el archivo físico si ninguna otra alerta del grupo lo usa
            foreach ($rutas as $ruta) {
                AlertaEvidencia::borrarArchivoSiHuerfano($ruta);
            }
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
