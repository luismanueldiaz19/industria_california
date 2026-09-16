<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Helpers\TextNormalizer;

class ProduccionAgrupadaController extends Controller
{
    public function porProducto(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

        $query = DB::table('orden_produccion_detalles')
            ->join('orden_produccions', 'orden_produccions.id', '=', 'orden_produccion_detalles.orden_produccion_id')
            ->join('inventario_productos', 'inventario_productos.id', '=', 'orden_produccion_detalles.producto_id')
            ->where('orden_produccion_detalles.estado', 'pendiente')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->select(
                'inventario_productos.id as producto_id',
                'inventario_productos.codigo as producto_codigo',
                'inventario_productos.nombre as producto_nombre',
                DB::raw('SUM(orden_produccion_detalles.cantidad_faltante) as cantidad_total')
            )
            ->groupBy('inventario_productos.id', 'inventario_productos.codigo', 'inventario_productos.nombre');

        if ($search) {
            $normalizedSearch = TextNormalizer::normalize($search);
            $query->where(function($q) use ($normalizedSearch) {
                $q->where(DB::raw('LOWER(inventario_productos.codigo)'), 'like', "%{$normalizedSearch}%")
                  ->orWhere(DB::raw('LOWER(inventario_productos.nombre)'), 'like', "%{$normalizedSearch}%");
            });
        }

        return response()->json($query->paginate($perPage));
    }

    public function porPedido(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

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

        return response()->json($query->paginate($perPage));
    }

    public function porCliente(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        $search = $request->input('search');

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

        return response()->json($query->paginate($perPage));
    }

    public function porFecha(Request $request)
    {
        $perPage = min(max((int) $request->input('per_page', 30), 5), 100);
        
        $query = DB::table('orden_produccions')
            ->where('orden_produccions.estado', '!=', 'lista')
            ->select(
                DB::raw("COALESCE(CAST(DATE(fecha_estimada_entrega) AS VARCHAR), 'Sin fecha') as fecha"),
                DB::raw("COUNT(orden_produccions.id) as cantidad_ordenes")
            )
            ->groupBy(DB::raw("COALESCE(CAST(DATE(fecha_estimada_entrega) AS VARCHAR), 'Sin fecha')"))
            ->orderBy('fecha', 'asc');

        // Note: Filtering by text date is uncommon, but we allow simple exact matches
        if ($search = $request->input('search')) {
            $query->where(DB::raw('DATE(fecha_estimada_entrega)'), 'like', "%{$search}%");
        }

        return response()->json($query->paginate($perPage));
    }
}
