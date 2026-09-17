<?php

namespace App\Modules\Produccion\Repositories;

use App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface;
use App\Modules\Produccion\Models\OrdenProduccion;
use App\Modules\Produccion\Models\OrdenProduccionDetalle;
use Illuminate\Support\Facades\DB;
use App\Helpers\TextNormalizer;

class ProduccionRepository implements ProduccionRepositoryInterface
{
    public function getAgrupadoPorProducto(int $perPage, ?string $search)
    {
        $query = DB::table('orden_produccion_detalles')
            ->join('orden_produccions', 'orden_produccions.id', '=', 'orden_produccion_detalles.orden_produccion_id')
            ->join('products', 'products.id', '=', 'orden_produccion_detalles.producto_id')
            ->where('orden_produccion_detalles.estado', 'pendiente')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->select(
                'products.id as producto_id',
                'products.codigo as producto_codigo',
                'products.descripcion as producto_nombre',
                DB::raw('SUM(orden_produccion_detalles.cantidad_faltante) as cantidad_total')
            )
            ->groupBy('products.id', 'products.codigo', 'products.descripcion');

        if ($search) {
            $normalizedSearch = TextNormalizer::normalize($search);
            $query->where(function($q) use ($normalizedSearch) {
                $q->where(DB::raw('LOWER(products.codigo)'), 'like', "%{$normalizedSearch}%")
                  ->orWhere(DB::raw('LOWER(products.descripcion)'), 'like', "%{$normalizedSearch}%");
            });
        }

        return $query->paginate($perPage);
    }

    public function getAgrupadoPorPedido(int $perPage, ?string $search)
    {
        $query = DB::table('orden_produccions')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->whereNotNull('orden_produccions.pedido_id')
            ->join('ledhouse_clientes', 'ledhouse_clientes.id', '=', 'orden_produccions.cliente_id')
            ->select(
                'orden_produccions.pedido_id',
                'ledhouse_clientes.nombre as cliente_nombre',
                DB::raw('COUNT(orden_produccions.id) as cantidad_ordenes'),
                DB::raw('MIN(orden_produccions.created_at) as fecha_creacion')
            )
            ->groupBy('orden_produccions.pedido_id', 'ledhouse_clientes.nombre');

        if ($search) {
            $normalizedSearch = TextNormalizer::normalize($search);
            $query->where(function($q) use ($normalizedSearch, $search) {
                $q->where('orden_produccions.pedido_id', 'like', "%{$search}%")
                  ->orWhere(DB::raw('LOWER(ledhouse_clientes.nombre)'), 'like', "%{$normalizedSearch}%");
            });
        }

        return $query->paginate($perPage);
    }

    public function getAgrupadoPorCliente(int $perPage, ?string $search)
    {
        $query = DB::table('orden_produccions')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->join('ledhouse_clientes', 'ledhouse_clientes.id', '=', 'orden_produccions.cliente_id')
            ->select(
                'ledhouse_clientes.id as cliente_id',
                'ledhouse_clientes.nombre as cliente_nombre',
                DB::raw('COUNT(orden_produccions.id) as cantidad_ordenes')
            )
            ->groupBy('ledhouse_clientes.id', 'ledhouse_clientes.nombre');

        if ($search) {
            $normalizedSearch = TextNormalizer::normalize($search);
            $query->where(DB::raw('LOWER(ledhouse_clientes.nombre)'), 'like', "%{$normalizedSearch}%");
        }

        return $query->paginate($perPage);
    }

    public function getAgrupadoPorFecha(int $perPage, ?string $search)
    {
        $query = DB::table('orden_produccions')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->select(
                DB::raw("COALESCE(CAST(DATE(fecha_estimada_entrega) AS VARCHAR), 'Sin fecha') as fecha"),
                DB::raw("COUNT(orden_produccions.id) as cantidad_ordenes")
            )
            ->groupBy(DB::raw("COALESCE(CAST(DATE(fecha_estimada_entrega) AS VARCHAR), 'Sin fecha')"))
            ->orderBy('fecha', 'asc');

        if ($search) {
            $query->where(DB::raw('DATE(fecha_estimada_entrega)'), 'like', "%{$search}%");
        }

        return $query->paginate($perPage);
    }

    public function crearOrdenAutomatica(array $datosOrden, array $detalles): OrdenProduccion
    {
        return DB::transaction(function () use ($datosOrden, $detalles) {
            $ordenProduccion = OrdenProduccion::create($datosOrden);

            foreach ($detalles as $df) {
                $df['orden_produccion_id'] = $ordenProduccion->id;
                OrdenProduccionDetalle::create($df);
            }

            return $ordenProduccion;
        });
    }
}
