<?php

namespace App\Modules\CuentasPorCobrar\Services;

use App\Helpers\TextNormalizer;
use App\Models\User;
use App\Modules\CuentasPorCobrar\Enums\EstadoCuarentenaCxc;
use App\Modules\CuentasPorCobrar\Enums\TipoNotaCxc;
use App\Modules\CuentasPorCobrar\Models\CuentaPorCobrar;
use App\Modules\CuentasPorCobrar\Models\CxcCuarentena;
use Exception;
use Illuminate\Support\Facades\DB;

class CxcCuarentenaService
{
    /**
     * Envía una CXC a cuarentena: crea la nota pendiente con snapshot
     * completo y elimina la CXC de ledhouse_cxcs.
     *
     * Los archivos físicos de evidencias NO se eliminan (quedan
     * referenciados en el snapshot).
     */
    public function enviar(int $cxcId, array $datos, User $admin): CxcCuarentena
    {
        return DB::transaction(fn () => $this->moverACuarentena($cxcId, $datos, $admin));
    }

    /**
     * Envía varias CXC a cuarentena con el mismo tipo, motivo y justificación.
     * El monto de cada nota es el monto pendiente de cada factura.
     *
     * @return array<int, CxcCuarentena>
     */
    public function enviarMasivo(array $ids, array $datos, User $admin): array
    {
        return DB::transaction(function () use ($ids, $datos, $admin) {
            $resultado = [];
            foreach (array_unique($ids) as $id) {
                $datosItem = $datos;
                unset($datosItem['monto_nota']); // usa el pendiente de cada factura
                $resultado[] = $this->moverACuarentena((int) $id, $datosItem, $admin);
            }
            return $resultado;
        });
    }

    private function moverACuarentena(int $cxcId, array $datos, User $admin): CxcCuarentena
    {
        $cxc = CuentaPorCobrar::with([
            'cliente',
            'vendedor',
            'soportes',
            'alertas.evidencias',
            'evidencias',
        ])->lockForUpdate()->find($cxcId);

        if (!$cxc) {
            throw new Exception("La cuenta por cobrar #{$cxcId} no existe o ya fue enviada a cuarentena.");
        }

        $montoNota = isset($datos['monto_nota'])
            ? (float) $datos['monto_nota']
            : (float) $cxc->monto_pendiente;

        if ($montoNota <= 0) {
            throw new Exception("El documento {$cxc->documento} no tiene monto pendiente. Indique el monto de la nota.");
        }

        $cuarentena = CxcCuarentena::create([
            'cxc_id_original'   => $cxc->id,
            'documento'         => $cxc->documento,
            'cliente_id'        => $cxc->cliente_id,
            'cliente_nombre'    => $cxc->cliente?->nombre,
            'vendedor_id'       => $cxc->vendedor_id,
            'vendedor_nombre'   => $cxc->vendedor?->name,
            'fecha_factura'     => $cxc->fecha_factura,
            'fecha_vencimiento' => $cxc->fecha_vencimiento,
            'monto_factura'     => (float) $cxc->monto_factura,
            'monto_pagado'      => (float) $cxc->monto_pagado,
            'monto_pendiente'   => (float) $cxc->monto_pendiente,
            'tipo_nota'         => TipoNotaCxc::from($datos['tipo_nota'])->value,
            'monto_nota'        => $montoNota,
            'motivo'            => $datos['motivo'],
            'justificacion'     => $datos['justificacion'],
            'estado'            => EstadoCuarentenaCxc::Pendiente->value,
            'snapshot'          => $this->construirSnapshot($cxc),
            'enviado_por'       => $admin->id,
        ]);

        // Borra la CXC. Soportes / alertas / evidencias (filas) se eliminan
        // por cascade en BD; su contenido queda preservado en el snapshot.
        $cxc->delete();

        return $cuarentena->load(['cliente:id,nombre', 'vendedor:id,name', 'enviadoPor:id,name']);
    }

    private function construirSnapshot(CuentaPorCobrar $cxc): array
    {
        $estado = $cxc->estado;

        return [
            'cxc' => [
                'id'                => $cxc->id,
                'documento'         => $cxc->documento,
                'cliente_id'        => $cxc->cliente_id,
                'vendedor_id'       => $cxc->vendedor_id,
                'monto_factura'     => (float) $cxc->monto_factura,
                'monto_pagado'      => (float) $cxc->monto_pagado,
                'monto_pendiente'   => (float) $cxc->monto_pendiente,
                'fecha_factura'     => $cxc->fecha_factura?->format('Y-m-d'),
                'fecha_vencimiento' => $cxc->fecha_vencimiento?->format('Y-m-d'),
                'estado'            => $estado instanceof \BackedEnum ? $estado->value : $estado,
                'created_at'        => $cxc->created_at?->toDateTimeString(),
                'updated_at'        => $cxc->updated_at?->toDateTimeString(),
            ],
            'soportes'    => $cxc->soportes->toArray(),
            'alertas'     => $cxc->alertas->toArray(),
            'evidencias'  => $cxc->evidencias->toArray(),
            'archivado_en' => now()->toDateTimeString(),
        ];
    }

    public function listar(array $filters = [])
    {
        $query = CxcCuarentena::with(['cliente:id,nombre', 'vendedor:id,name', 'enviadoPor:id,name', 'resueltoPor:id,name']);

        if (!empty($filters['estado']) && $filters['estado'] !== 'todos') {
            $query->where('estado', $filters['estado']);
        }
        if (!empty($filters['tipo_nota']) && $filters['tipo_nota'] !== 'todos') {
            $query->where('tipo_nota', $filters['tipo_nota']);
        }
        if (!empty($filters['vendedor_id'])) {
            $query->where('vendedor_id', $filters['vendedor_id']);
        }
        if (!empty($filters['cliente_id'])) {
            $query->where('cliente_id', $filters['cliente_id']);
        }
        if (!empty($filters['search'])) {
            $search = TextNormalizer::normalize(trim($filters['search']));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(cliente_nombre) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(numero_nota_externa) LIKE ?', ["%{$search}%"]);
            });
        }
        if (!empty($filters['start_date']) && !empty($filters['end_date'])) {
            $query->whereBetween('created_at', [
                $filters['start_date'] . ' 00:00:00',
                $filters['end_date'] . ' 23:59:59',
            ]);
        }

        $query->orderByDesc('created_at');

        $perPage = (int) ($filters['per_page'] ?? 25);
        return $query->paginate($perPage);
    }

    public function obtener(int $id): CxcCuarentena
    {
        return CxcCuarentena::with(['cliente:id,nombre', 'vendedor:id,name', 'enviadoPor:id,name', 'resueltoPor:id,name'])
            ->findOrFail($id);
    }

    public function aplicar(int $id, array $datos, User $admin): CxcCuarentena
    {
        return $this->resolver($id, EstadoCuarentenaCxc::Aplicada, $datos, $admin);
    }

    /**
     * Anula la nota. La CXC NO se restaura en el sistema local.
     */
    public function anular(int $id, array $datos, User $admin): CxcCuarentena
    {
        if (empty($datos['nota_resolucion'])) {
            throw new Exception('Debe indicar el motivo de la anulación.');
        }
        return $this->resolver($id, EstadoCuarentenaCxc::Anulada, $datos, $admin);
    }

    private function resolver(int $id, EstadoCuarentenaCxc $nuevo, array $datos, User $admin): CxcCuarentena
    {
        return DB::transaction(function () use ($id, $nuevo, $datos, $admin) {
            $cuarentena = CxcCuarentena::lockForUpdate()->findOrFail($id);

            if (!$cuarentena->estaPendiente()) {
                throw new Exception("La nota ya está {$cuarentena->estado->label()} y no puede modificarse.");
            }

            $cuarentena->update([
                'estado'              => $nuevo->value,
                'numero_nota_externa' => $datos['numero_nota_externa'] ?? $cuarentena->numero_nota_externa,
                'nota_resolucion'     => $datos['nota_resolucion'] ?? null,
                'fecha_resolucion'    => now(),
                'resuelto_por'        => $admin->id,
            ]);

            return $this->obtener($cuarentena->id);
        });
    }

    public function resumen(): array
    {
        $pendientes = CxcCuarentena::where('estado', EstadoCuarentenaCxc::Pendiente->value);

        return [
            'pendiente_credito' => (float) (clone $pendientes)->where('tipo_nota', TipoNotaCxc::Credito->value)->sum('monto_nota'),
            'pendiente_debito'  => (float) (clone $pendientes)->where('tipo_nota', TipoNotaCxc::Debito->value)->sum('monto_nota'),
            'total_pendientes'  => (clone $pendientes)->count(),
            'total_aplicadas'   => CxcCuarentena::where('estado', EstadoCuarentenaCxc::Aplicada->value)->count(),
            'total_anuladas'    => CxcCuarentena::where('estado', EstadoCuarentenaCxc::Anulada->value)->count(),
        ];
    }
}
