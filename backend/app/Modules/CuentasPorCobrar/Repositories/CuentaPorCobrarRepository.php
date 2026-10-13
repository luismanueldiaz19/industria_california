<?php

namespace App\Modules\CuentasPorCobrar\Repositories;

use App\Helpers\TextNormalizer;
use App\Modules\Cliente\Models\Cliente;
use App\Modules\CuentasPorCobrar\Enums\EstadoCxc;
use App\Modules\CuentasPorCobrar\Models\CuentaPorCobrar;
use App\Modules\CuentasPorCobrar\Repositories\Contracts\CuentaPorCobrarRepositoryInterface;

class CuentaPorCobrarRepository implements CuentaPorCobrarRepositoryInterface
{
    public function getAll(array $filters = [], ?int $perPage = null)
    {
        $query = CuentaPorCobrar::with(['cliente', 'vendedor'])
            ->withCount('soportes as total_intervenciones')
            ->withMax('soportes as ultima_fecha_visita', 'fecha_visita')
            ->withCount(['alertas as alertas_pendientes' => function ($q) {
                $q->where('estado_alerta', 'pendiente');
            }]);

        // Filtro por vendedor
        if (!empty($filters['vendedor_id'])) {
            $query->where('vendedor_id', $filters['vendedor_id']);
        }

        // Filtro por cliente
        if (!empty($filters['cliente_id'])) {
            $query->where('cliente_id', $filters['cliente_id']);
        }

        // Búsqueda por documento o cliente
        if (!empty($filters['search'])) {
            $rawSearch = trim($filters['search']);
            $search = TextNormalizer::normalize($rawSearch);
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"])
                  ->orWhereHas('cliente', function ($q2) use ($search) {
                      $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                         ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                  });
            });
        }

        // Filtro por estado
        if (!empty($filters['estado']) && $filters['estado'] !== 'Todos' && $filters['estado'] !== 'Todos los Estados') {
            $query->where('estado', $filters['estado']);
        } else {
            // Por defecto ocultar pagadas a menos que se especifique
            if (!isset($filters['incluir_pagadas']) || !$filters['incluir_pagadas']) {
                $query->where('estado', '!=', EstadoCxc::Pagado->value);
            }
        }

        // Filtro por vencidos
        if (!empty($filters['vencidos']) && $filters['vencidos'] == '1') {
            $query->where('monto_pendiente', '>', 0)
                  ->where('estado', '!=', EstadoCxc::Pagado->value)
                  ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
        }

        // Filtro por soportes con fecha de visita
        if (!empty($filters['con_visita']) && $filters['con_visita'] == '1') {
            $query->whereHas('soportes', function ($q) {
                $q->whereNotNull('fecha_visita');
            });
        }

        // Rango de fechas
        if (!empty($filters['start_date']) && !empty($filters['end_date'])) {
            $query->whereBetween('fecha_factura', [$filters['start_date'], $filters['end_date']]);
        }

        // Orden
        if (!empty($filters['orden_monto'])) {
            $query->orderBy('monto_pendiente', $filters['orden_monto'] === 'desc' ? 'desc' : 'asc');
        } elseif (!empty($filters['sort_by'])) {
            $query->orderBy($filters['sort_by'], $filters['sort_order'] ?? 'asc');
        } else {
            $query->orderBy('fecha_vencimiento', 'asc');
        }

        if ($perPage !== null || !empty($filters['paginate']) || !empty($filters['page'])) {
            return $query->paginate($perPage ?? ($filters['per_page'] ?? 25));
        }

        return $query->get();
    }

    public function find(int $id): CuentaPorCobrar
    {
        return CuentaPorCobrar::with([
            'soportes',
            'alertas.vendedor',
            'alertas.evidencias',
            'alertas.revisador',
            'evidencias.subidoPor',
            'cliente',
            'vendedor',
        ])->findOrFail($id);
    }

    public function create(array $data): CuentaPorCobrar
    {
        $montoFactura   = (float) ($data['monto_factura'] ?? 0);
        $montoPagado    = (float) ($data['monto_pagado'] ?? 0);
        $montoPendiente = $montoFactura - $montoPagado;

        $data['monto_pagado']    = $montoPagado;
        $data['monto_pendiente'] = $montoPendiente;
        $data['estado']          = $data['estado'] ?? ($montoPendiente <= 0 ? EstadoCxc::Pagado->value : EstadoCxc::Pendiente->value);

        return CuentaPorCobrar::create($data);
    }

    public function update(int $id, array $data): CuentaPorCobrar
    {
        $cxc = CuentaPorCobrar::findOrFail($id);

        if (array_key_exists('monto_factura', $data) || array_key_exists('monto_pagado', $data)) {
            $factura  = (float) (array_key_exists('monto_factura', $data) ? $data['monto_factura'] : $cxc->monto_factura);
            $pagado   = (float) (array_key_exists('monto_pagado', $data) ? $data['monto_pagado'] : $cxc->monto_pagado);
            $data['monto_pendiente'] = $factura - $pagado;

            if (!isset($data['estado']) && $data['monto_pendiente'] <= 0) {
                $data['estado'] = EstadoCxc::Pagado->value;
            }
        }

        $cxc->update($data);
        return $cxc->fresh(['cliente', 'vendedor']);
    }

    public function delete(int $id): bool
    {
        $cxc = CuentaPorCobrar::findOrFail($id);
        return (bool) $cxc->delete();
    }

    public function getMisCxc(int $vendedorId, array $filters = [], ?int $perPage = 20): array
    {
        $query = CuentaPorCobrar::with(['cliente', 'evidencias'])
            ->withCount(['alertas as alertas_pendientes' => function ($q) {
                $q->where('estado_alerta', 'pendiente');
            }])
            ->where('vendedor_id', $vendedorId);

        if (!empty($filters['search'])) {
            $rawSearch = trim($filters['search']);
            $search = TextNormalizer::normalize($rawSearch);
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(documento) LIKE ?', ["%{$search}%"])
                  ->orWhereHas('cliente', function ($q2) use ($search) {
                      $q2->whereRaw('LOWER(nombre) LIKE ?', ["%{$search}%"])
                         ->orWhereRaw('LOWER(documento) LIKE ?', ["%{$search}%"]);
                  });
            });
        }

        if (!empty($filters['vencidos']) && $filters['vencidos'] == '1') {
            $query->where('monto_pendiente', '>', 0)
                  ->where('estado', '!=', EstadoCxc::Pagado->value)
                  ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
        }

        if (!empty($filters['con_alerta']) && $filters['con_alerta'] == '1') {
            $query->whereHas('alertas');
        }

        $query->where('estado', '!=', EstadoCxc::Pagado->value);

        if (!empty($filters['orden_monto'])) {
            $query->orderBy('monto_pendiente', $filters['orden_monto'] === 'desc' ? 'desc' : 'asc');
        } else {
            $query->orderBy('fecha_vencimiento', 'asc');
        }

        $totalesQuery = clone $query;
        $totalFacturado = (float) $totalesQuery->sum('monto_factura');
        $totalPendiente = (float) $totalesQuery->sum('monto_pendiente');

        $totalesQueryVencidos = clone $query;
        $totalVencido = (float) $totalesQueryVencidos
            ->where('monto_pendiente', '>', 0)
            ->where('estado', '!=', EstadoCxc::Pagado->value)
            ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'))
            ->sum('monto_pendiente');

        $paginator = $query->paginate($perPage ?? ($filters['per_page'] ?? 20));

        return [
            'paginator'        => $paginator,
            'totales_globales' => [
                'facturado' => $totalFacturado,
                'pendiente' => $totalPendiente,
                'vencido'   => $totalVencido,
            ],
        ];
    }

    public function groupedByCliente(array $filters = [])
    {
        $queryCxc = function ($q) use ($filters) {
            $q->where('estado', '!=', EstadoCxc::Pagado->value);

            if (!empty($filters['vendedor_id'])) {
                $q->where('vendedor_id', $filters['vendedor_id']);
            }
            if (!empty($filters['vencidos']) && $filters['vencidos'] == '1') {
                $q->where('monto_pendiente', '>', 0)
                  ->whereDate('fecha_vencimiento', '<', now()->format('Y-m-d'));
            }
            if (!empty($filters['start_date']) && !empty($filters['end_date'])) {
                $q->whereBetween('fecha_factura', [$filters['start_date'], $filters['end_date']]);
            }
        };

        return Cliente::whereHas('cxcs', $queryCxc)
            ->withSum(['cxcs as total_facturado' => $queryCxc], 'monto_factura')
            ->withSum(['cxcs as total_pendiente' => $queryCxc], 'monto_pendiente')
            ->get();
    }

    public function getResumen(): array
    {
        $hoy = now()->format('Y-m-d');
        $totalFacturado = (float) CuentaPorCobrar::sum('monto_factura');
        $totalPendiente = (float) CuentaPorCobrar::where('estado', '!=', EstadoCxc::Pagado->value)->sum('monto_pendiente');
        $totalVencido   = (float) CuentaPorCobrar::where('estado', '!=', EstadoCxc::Pagado->value)
            ->where('monto_pendiente', '>', 0)
            ->whereDate('fecha_vencimiento', '<', $hoy)
            ->sum('monto_pendiente');
        $totalAlertasPendientes = CuentaPorCobrar::whereHas('alertas', function ($q) {
            $q->where('estado_alerta', 'pendiente');
        })->count();

        return [
            'total_documentos'         => CuentaPorCobrar::count(),
            'total_facturado'          => $totalFacturado,
            'total_pendiente'          => $totalPendiente,
            'total_vencido'            => $totalVencido,
            'total_alertas_pendientes' => $totalAlertasPendientes,
        ];
    }
}
