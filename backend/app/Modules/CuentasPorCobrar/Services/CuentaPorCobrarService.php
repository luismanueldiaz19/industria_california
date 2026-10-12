<?php

namespace App\Modules\CuentasPorCobrar\Services;

use App\Helpers\TextNormalizer;
use App\Models\User;
use App\Modules\Cliente\Models\Cliente;
use App\Modules\CuentasPorCobrar\Enums\EstadoAlertaCxc;
use App\Modules\CuentasPorCobrar\Enums\EstadoCxc;
use App\Modules\CuentasPorCobrar\Enums\TipoEvidenciaCxc;
use App\Modules\CuentasPorCobrar\Models\CuentaPorCobrar;
use App\Modules\CuentasPorCobrar\Models\CxcAlerta;
use App\Modules\CuentasPorCobrar\Models\CxcEvidencia;
use App\Modules\CuentasPorCobrar\Models\CxcSoporte;
use App\Modules\CuentasPorCobrar\Repositories\Contracts\CuentaPorCobrarRepositoryInterface;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use PhpOffice\PhpSpreadsheet\IOFactory;

class CuentaPorCobrarService
{
    public function __construct(
        private readonly CuentaPorCobrarRepositoryInterface $repository
    ) {}

    public function listar(array $filters = [], ?int $perPage = null)
    {
        return $this->repository->getAll($filters, $perPage);
    }

    public function obtener(int $id): CuentaPorCobrar
    {
        return $this->repository->find($id);
    }

    public function crear(array $data): CuentaPorCobrar
    {
        return $this->repository->create($data);
    }

    public function actualizar(int $id, array $data): CuentaPorCobrar
    {
        return $this->repository->update($id, $data);
    }

    public function eliminar(int $id): bool
    {
        return DB::transaction(function () use ($id) {
            $cxc = $this->repository->find($id);

            // Eliminar archivos físicos de evidencias
            foreach ($cxc->evidencias as $evidencia) {
                if ($evidencia->ruta_archivo && Storage::disk('public')->exists($evidencia->ruta_archivo)) {
                    Storage::disk('public')->delete($evidencia->ruta_archivo);
                }
            }

            return $this->repository->delete($id);
        });
    }

    public function misCxc(int $vendedorId, array $filters = [], ?int $perPage = 20): array
    {
        return $this->repository->getMisCxc($vendedorId, $filters, $perPage);
    }

    public function agrupadoPorCliente(array $filters = [])
    {
        return $this->repository->groupedByCliente($filters);
    }

    public function resumen(): array
    {
        return $this->repository->getResumen();
    }

    // ─────────────────────────────────────────────────────────────
    // Alertas
    // ─────────────────────────────────────────────────────────────

    public function listarAlertas(array $filters = [], ?User $usuario = null)
    {
        $query = CxcAlerta::with(['cxc.cliente', 'cxc.evidencias', 'vendedor', 'evidencias', 'revisador'])
            ->orderBy('created_at', 'desc');

        if ($usuario && $usuario->hasRole('vendedor')) {
            $query->where('vendedor_id', $usuario->id);
            if (empty($filters['start_date']) && empty($filters['end_date']) && empty($filters['estado'])) {
                $query->where('estado_alerta', '!=', EstadoAlertaCxc::Procesada->value);
            }
        } elseif (!empty($filters['vendedor_id'])) {
            $query->where('vendedor_id', $filters['vendedor_id']);
        }

        if (!empty($filters['start_date']) && !empty($filters['end_date'])) {
            $query->whereBetween('created_at', [
                $filters['start_date'] . ' 00:00:00',
                $filters['end_date'] . ' 23:59:59',
            ]);
        }

        if (!empty($filters['tipo']) && $filters['tipo'] !== 'todos') {
            $query->where('tipo', $filters['tipo']);
        }

        if (!empty($filters['estado']) && $filters['estado'] !== 'todos') {
            if ($filters['estado'] === 'pendiente') {
                $query->where('estado_alerta', '!=', EstadoAlertaCxc::Procesada->value);
            } else {
                $query->where('estado_alerta', $filters['estado']);
            }
        }

        if (!empty($filters['search'])) {
            $search = TextNormalizer::normalize(trim($filters['search']));
            $query->where(function ($q) use ($search) {
                $q->whereHas('cxc.cliente', function ($q2) use ($search) {
                    $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                       ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                })->orWhereHas('cxc', function ($q3) use ($search) {
                    $q3->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                });
            });
        }

        if (!empty($filters['cliente_id'])) {
            $query->whereHas('cxc', function ($q) use ($filters) {
                $q->where('cliente_id', $filters['cliente_id']);
            });
        }

        if (!empty($filters['paginate']) || !empty($filters['page']) || !empty($filters['limit'])) {
            $perPage = $filters['limit'] ?? ($filters['per_page'] ?? 20);
            return $query->paginate($perPage);
        }

        return $query->get();
    }

    public function agregarAlerta(int $cxcId, array $data, User $vendedor): CxcAlerta
    {
        $cxc = $this->repository->find($cxcId);

        if ($vendedor->hasRole('vendedor') && (int)$cxc->vendedor_id !== (int)$vendedor->id) {
            throw new Exception('No tienes permiso para alertar este documento.');
        }

        return CxcAlerta::create([
            'ledhouse_cxc_id' => $cxc->id,
            'vendedor_id'     => $vendedor->id,
            'tipo'            => $data['tipo'] ?? 'informacion',
            'monto_informado' => $data['monto_informado'] ?? null,
            'nota'            => $data['nota'],
            'estado_alerta'   => EstadoAlertaCxc::Pendiente->value,
        ])->load('vendedor');
    }

    public function resolverAlerta(int $alertaId, array $data, User $revisor): CxcAlerta
    {
        return DB::transaction(function () use ($alertaId, $data, $revisor) {
            $alerta = CxcAlerta::findOrFail($alertaId);

            $alerta->update([
                'estado_alerta'  => $data['estado_alerta'],
                'revisada_por'   => $revisor->id,
                'fecha_revision' => now(),
            ]);

            if (!empty($data['actualizar_cxc'])) {
                $cxc = $alerta->cxc;
                $updates = [];

                if (isset($data['monto_pagado'])) {
                    $updates['monto_pagado']   = $data['monto_pagado'];
                    $updates['monto_pendiente'] = (float)$cxc->monto_factura - (float)$data['monto_pagado'];
                }
                if (isset($data['estado_cxc'])) {
                    $updates['estado'] = $data['estado_cxc'];
                }

                if (!empty($updates)) {
                    $cxc->update($updates);
                }
            }

            return $alerta->load(['vendedor', 'revisador', 'cxc']);
        });
    }

    public function eliminarAlerta(int $alertaId, User $usuario): void
    {
        DB::transaction(function () use ($alertaId, $usuario) {
            $alerta = CxcAlerta::findOrFail($alertaId);

            if ($usuario->hasRole('vendedor') && (int)$alerta->vendedor_id !== (int)$usuario->id) {
                throw new Exception('No tienes permiso para eliminar esta alerta.');
            }

            $evidencias = CxcEvidencia::where('alerta_id', $alerta->id)
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

    public function updateTipoAlerta(int $alertaId, string $tipo): CxcAlerta
    {
        $alerta = CxcAlerta::findOrFail($alertaId);
        $alerta->update(['tipo' => $tipo]);
        return $alerta->load(['vendedor', 'revisador', 'cxc']);
    }

    // ─────────────────────────────────────────────────────────────
    // Soportes
    // ─────────────────────────────────────────────────────────────

    public function listarSoportes(int $cxcId)
    {
        $cxc = $this->repository->find($cxcId);
        return $cxc->soportes()->orderBy('fecha', 'desc')->get();
    }

    public function agregarSoporte(int $cxcId, array $data): CxcSoporte
    {
        $cxc = $this->repository->find($cxcId);
        return $cxc->soportes()->create($data);
    }

    // ─────────────────────────────────────────────────────────────
    // Evidencias
    // ─────────────────────────────────────────────────────────────

    public function listarEvidencias(int $cxcId)
    {
        $cxc = $this->repository->find($cxcId);
        return $cxc->evidencias()->with('subidoPor')->orderBy('created_at', 'desc')->get();
    }

    public function subirEvidencia(int $cxcId, UploadedFile $file, ?int $alertaId, User $usuario): CxcEvidencia
    {
        $cxc = $this->repository->find($cxcId);
        $ext = strtolower($file->getClientOriginalExtension());

        $path = $file->store("cxc-evidencias/{$cxc->id}", 'public');

        return CxcEvidencia::create([
            'ledhouse_cxc_id' => $cxc->id,
            'alerta_id'       => $alertaId,
            'subido_por'      => $usuario->id,
            'nombre_archivo'  => $file->getClientOriginalName(),
            'ruta_archivo'    => $path,
            'tipo_archivo'    => $ext,
        ])->load('subidoPor');
    }

    // ─────────────────────────────────────────────────────────────
    // Auditoría de Calidad de Datos
    // ─────────────────────────────────────────────────────────────

    public function auditoria(User $usuario): array
    {
        if (!$usuario->hasRole('admin')) {
            throw new Exception('No autorizado para ver auditoría de cuentas por cobrar.');
        }

        $results = [];

        // 1. Documentos duplicados (global)
        $dupGlobal = DB::table('ledhouse_cxcs')
            ->select('documento', DB::raw('COUNT(*) as total'))
            ->groupBy('documento')
            ->havingRaw('COUNT(*) > 1')
            ->orderByDesc('total')
            ->get();

        $results['duplicados_documento'] = [
            'label'       => 'Documentos Duplicados (Global)',
            'descripcion' => 'El mismo número de documento aparece más de una vez en el sistema.',
            'nivel'       => 'warning',
            'total'       => $dupGlobal->count(),
            'registros'   => $dupGlobal->map(function ($r) {
                $afectados = DB::table('ledhouse_cxcs as c')
                    ->leftJoin('ledhouse_clientes as cl', 'c.cliente_id', '=', 'cl.id')
                    ->leftJoin('users as u', 'c.vendedor_id', '=', 'u.id')
                    ->where('c.documento', $r->documento)
                    ->select('c.id', 'c.documento', 'c.monto_factura', 'c.monto_pendiente', 'c.estado', 'c.fecha_factura', 'cl.nombre as cliente', 'u.name as vendedor')
                    ->get();
                return ['documento' => $r->documento, 'repeticiones' => $r->total, 'afectados' => $afectados];
            }),
        ];

        // 2. Documento duplicado por MISMO cliente
        $dupCliente = DB::table('ledhouse_cxcs as c')
            ->leftJoin('ledhouse_clientes as cl', 'c.cliente_id', '=', 'cl.id')
            ->leftJoin('users as u', 'c.vendedor_id', '=', 'u.id')
            ->select('c.cliente_id', 'c.documento', 'cl.nombre as cliente', 'u.name as vendedor', DB::raw('COUNT(c.id) as repeticiones'))
            ->groupBy('c.cliente_id', 'c.documento', 'cl.nombre', 'u.name')
            ->havingRaw('COUNT(c.id) > 1')
            ->orderByDesc('repeticiones')
            ->get();

        $results['duplicados_cliente_documento'] = [
            'label'       => 'Documento Duplicado por Cliente',
            'descripcion' => 'Un mismo documento existe más de una vez para el mismo cliente.',
            'nivel'       => 'danger',
            'total'       => $dupCliente->count(),
            'registros'   => $dupCliente,
        ];

        // 3. Montos inconsistentes: pendiente ≠ factura - pagado
        $montosIncon = DB::table('ledhouse_cxcs as c')
            ->leftJoin('ledhouse_clientes as cl', 'c.cliente_id', '=', 'cl.id')
            ->leftJoin('users as u', 'c.vendedor_id', '=', 'u.id')
            ->select(
                'c.id', 'c.documento', 'c.monto_factura', 'c.monto_pagado', 'c.monto_pendiente', 'c.estado',
                'cl.nombre as cliente', 'u.name as vendedor',
                DB::raw('(c.monto_factura - c.monto_pagado) as pendiente_calculado'),
                DB::raw('(c.monto_pendiente - (c.monto_factura - c.monto_pagado)) as diferencia')
            )
            ->whereRaw('ROUND(c.monto_pendiente, 2) <> ROUND((c.monto_factura - c.monto_pagado), 2)')
            ->orderByDesc(DB::raw('ABS(c.monto_pendiente - (c.monto_factura - c.monto_pagado))'))
            ->limit(50)
            ->get();

        $results['montos_inconsistentes'] = [
            'label'       => 'Montos Inconsistentes',
            'descripcion' => 'El monto pendiente no coincide con (monto factura - monto pagado).',
            'nivel'       => 'danger',
            'total'       => $montosIncon->count(),
            'registros'   => $montosIncon,
        ];

        return $results;
    }

    // ─────────────────────────────────────────────────────────────
    // Sincronización Masiva & Importación
    // ─────────────────────────────────────────────────────────────

    public function syncPreview(UploadedFile $file): array
    {
        $spreadsheet = IOFactory::load($file->getPathname());
        $rows        = $spreadsheet->getActiveSheet()->toArray();
        array_shift($rows);

        $errores         = [];
        $nuevos          = [];
        $actualizaciones = [];

        foreach ($rows as $index => $row) {
            $fila              = $index + 2;
            $id_ext            = isset($row[0]) ? trim((string)$row[0]) : null;
            $documento         = isset($row[1]) ? trim((string)$row[1]) : null;
            $monto             = isset($row[2]) ? trim((string)$row[2]) : null;
            $fecha             = isset($row[3]) ? trim((string)$row[3]) : null;
            $vendedor_id_excel = isset($row[4]) ? trim((string)$row[4]) : null;

            if (empty($id_ext) || empty($documento) || empty($vendedor_id_excel)) {
                $errores[] = ['fila' => $fila, 'razon' => 'ID externo, documento o ID Vendedor vacío'];
                continue;
            }

            $vendedorFila = User::find($vendedor_id_excel);
            if (!$vendedorFila) {
                $errores[] = [
                    'fila'  => $fila,
                    'id_ext'=> $id_ext,
                    'razon' => "Vendedor con ID '{$vendedor_id_excel}' no encontrado.",
                ];
                continue;
            }

            $cliente = Cliente::where('id_cliente_externo', $id_ext)->first();
            if (!$cliente) {
                $errores[] = [
                    'fila'  => $fila,
                    'id_ext'=> $id_ext,
                    'razon' => "Cliente con ID externo '{$id_ext}' no encontrado en el sistema.",
                ];
                continue;
            }

            $cxcExistente = CuentaPorCobrar::where('documento', $documento)
                ->where('cliente_id', $cliente->id)
                ->first();

            $item = [
                'fila'           => $fila,
                'id_ext'         => $id_ext,
                'cliente_nombre' => $cliente->nombre,
                'cliente_id'     => $cliente->id,
                'documento'      => $documento,
                'monto_pendiente'=> (float)$monto,
                'fecha_factura'  => $fecha,
            ];

            if ($cxcExistente) {
                $item['cxc_id']         = $cxcExistente->id;
                $item['monto_anterior'] = (float)$cxcExistente->monto_pendiente;
                $actualizaciones[]      = $item;
            } else {
                $nuevos[] = $item;
            }
        }

        return [
            'resumen' => [
                'total_filas'     => count($rows),
                'errores'         => count($errores),
                'nuevos'          => count($nuevos),
                'actualizaciones' => count($actualizaciones),
            ],
            'errores'         => $errores,
            'nuevos'          => $nuevos,
            'actualizaciones' => $actualizaciones,
        ];
    }

    public function syncConfirm(UploadedFile $file): array
    {
        $spreadsheet = IOFactory::load($file->getPathname());
        $rows        = $spreadsheet->getActiveSheet()->toArray();
        array_shift($rows);

        $creados      = 0;
        $actualizados = 0;
        $omitidos     = 0;
        $errores      = [];

        DB::transaction(function () use ($rows, &$creados, &$actualizados, &$omitidos, &$errores) {
            foreach ($rows as $index => $row) {
                $fila              = $index + 2;
                $id_ext            = isset($row[0]) ? trim((string)$row[0]) : null;
                $documento         = isset($row[1]) ? trim((string)$row[1]) : null;
                $monto             = isset($row[2]) ? trim((string)$row[2]) : null;
                $fecha             = isset($row[3]) ? trim((string)$row[3]) : null;
                $vendedor_id_excel = isset($row[4]) ? trim((string)$row[4]) : null;

                if (empty($id_ext) || empty($documento) || empty($vendedor_id_excel)) {
                    $omitidos++;
                    continue;
                }

                $vendedorFila = User::find($vendedor_id_excel);
                if (!$vendedorFila) {
                    $errores[] = ['fila' => $fila, 'id_ext' => $id_ext, 'razon' => 'Vendedor no encontrado'];
                    $omitidos++;
                    continue;
                }

                $cliente = Cliente::where('id_cliente_externo', $id_ext)->first();
                if (!$cliente) {
                    $errores[] = ['fila' => $fila, 'id_ext' => $id_ext, 'razon' => 'Cliente no encontrado'];
                    $omitidos++;
                    continue;
                }

                $montoFloat = is_numeric($monto) ? (float)$monto : 0.0;
                $estado     = $montoFloat <= 0 ? EstadoCxc::Pagado->value : EstadoCxc::Pendiente->value;

                try {
                    $fechaObj          = Carbon::parse($fecha);
                    $fechaFacturaDb    = $fechaObj->format('Y-m-d');
                    $diasCredito       = $cliente->dias_credito ?? 0;
                    $fechaVencimiento  = $fechaObj->copy()->addDays($diasCredito)->format('Y-m-d');
                } catch (Exception $e) {
                    $fechaFacturaDb   = now()->format('Y-m-d');
                    $fechaVencimiento = now()->format('Y-m-d');
                }

                $existing = CuentaPorCobrar::where('documento', $documento)
                    ->where('cliente_id', $cliente->id)
                    ->first();

                if ($existing) {
                    $existing->update([
                        'monto_pendiente'   => $montoFloat,
                        'fecha_factura'     => $fechaFacturaDb,
                        'fecha_vencimiento' => $fechaVencimiento,
                        'estado'            => $estado,
                        'vendedor_id'       => $vendedorFila->id,
                    ]);
                    $actualizados++;
                } else {
                    CuentaPorCobrar::create([
                        'documento'         => $documento,
                        'cliente_id'        => $cliente->id,
                        'vendedor_id'       => $vendedorFila->id,
                        'monto_factura'     => $montoFloat,
                        'monto_pagado'      => 0,
                        'monto_pendiente'   => $montoFloat,
                        'fecha_factura'     => $fechaFacturaDb,
                        'fecha_vencimiento' => $fechaVencimiento,
                        'estado'            => $estado,
                    ]);
                    $creados++;
                }
            }
        });

        return [
            'message'      => 'Sincronización completada exitosamente.',
            'creados'      => $creados,
            'actualizados' => $actualizados,
            'omitidos'     => $omitidos,
            'errores'      => $errores,
        ];
    }

    public function importByCliente(int $clienteId, UploadedFile $file): array
    {
        $spreadsheet = IOFactory::load($file->getPathname());
        $rows        = $spreadsheet->getActiveSheet()->toArray();
        array_shift($rows);

        $importedCount = 0;
        $cliente       = Cliente::findOrFail($clienteId);
        $diasCredito   = $cliente->dias_credito ?? 0;

        foreach ($rows as $row) {
            $documento    = isset($row[0]) ? trim((string)$row[0]) : null;
            $monto        = isset($row[1]) ? trim((string)$row[1]) : null;
            $fechaFactura = isset($row[2]) ? trim((string)$row[2]) : null;
            $montoFactura = isset($row[3]) ? trim((string)$row[3]) : null;

            if ($documento && $monto !== null && $fechaFactura) {
                $montoFloat        = (float)$monto;
                $montoFacturaFloat = ($montoFactura !== '' && is_numeric($montoFactura)) ? (float)$montoFactura : $montoFloat;
                $estado            = $montoFloat <= 0 ? EstadoCxc::Pagado->value : EstadoCxc::Pendiente->value;

                try {
                    $fechaObj         = Carbon::parse($fechaFactura);
                    $fechaFacturaDb   = $fechaObj->format('Y-m-d');
                    $fechaVencimiento = $fechaObj->copy()->addDays($diasCredito)->format('Y-m-d');
                } catch (Exception $e) {
                    $fechaFacturaDb   = $fechaFactura;
                    $fechaVencimiento = $fechaFactura;
                }

                CuentaPorCobrar::updateOrCreate(
                    ['documento' => $documento, 'cliente_id' => $clienteId],
                    [
                        'monto_pendiente'   => $montoFloat,
                        'monto_factura'     => $montoFacturaFloat,
                        'fecha_factura'     => $fechaFacturaDb,
                        'fecha_vencimiento' => $fechaVencimiento,
                        'estado'            => $estado,
                        'monto_pagado'      => $estado === EstadoCxc::Pagado->value ? $montoFacturaFloat : 0,
                    ]
                );
                $importedCount++;
            }
        }

        return [
            'message'         => "Importado exitosamente. {$importedCount} registros procesados.",
            'registros_count' => $importedCount,
        ];
    }
}
