<?php

namespace App\Modules\Pedido\Services;

use App\Models\User;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Models\PedidoDetalle;
use App\Modules\Producto\Models\Producto;
use App\Models\InventarioMovimiento;
use App\Modules\Pedido\Repositories\Contracts\PedidoRepositoryInterface;
use App\Modules\Produccion\Services\ProduccionService;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;

class PedidoService
{
    public function __construct(
        private readonly PedidoRepositoryInterface $pedidos,
        private readonly ProduccionService $produccionService
    ) {}

    public function crear(array $datos, User $vendedor): Pedido
    {
        $idempotencyKey = $datos['idempotency_key'] ?? null;

        if ($idempotencyKey !== null) {
            $existente = $this->pedidos->buscarPorIdempotencyKey($idempotencyKey);
            if ($existente !== null) {
                return $existente;
            }
        }

        try {
            return DB::transaction(function () use ($datos, $vendedor, $idempotencyKey) {
                [$detalles, $total] = $this->prepararDetalles($datos['detalles']);

                $pedido = $this->pedidos->crear([
                    'cliente_id' => $datos['cliente_id'],
                    'ruta_id' => $datos['ruta_id'] ?? null,
                    'vendedor_id' => $vendedor->id,
                    'estado' => $datos['estado'],
                    'comentario' => $datos['comentario'] ?? null,
                    'num_factura' => $datos['num_factura'] ?? null,
                    'total' => $total,
                    'latitud' => $datos['latitud'] ?? null,
                    'longitud' => $datos['longitud'] ?? null,
                    'fecha_entrega' => $datos['fecha_entrega'] ?? null,
                    'nota_produccion' => $datos['nota_produccion'] ?? null,
                    'idempotency_key' => $idempotencyKey,
                ], $detalles);

                if ($datos['estado'] === 'enviado') {
                    $this->deducirInventario($pedido->load('detalles'));
                }

                return $pedido;
            });
        } catch (QueryException $e) {
            if ($idempotencyKey !== null && $this->esViolacionDeUnicidad($e)) {
                $existente = $this->pedidos->buscarPorIdempotencyKey($idempotencyKey);
                if ($existente !== null) {
                    return $existente;
                }
            }

            Log::error('Error al crear pedido', [
                'vendedor_id' => $vendedor->id,
                'cliente_id' => $datos['cliente_id'] ?? null,
                'mensaje' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    public function actualizar(Pedido $pedido, array $datos): Pedido
    {
        return DB::transaction(function () use ($pedido, $datos) {
            $originalEstado = $pedido->estado;

            $pedido->detalles()->delete(); // Clear old ones to easily sync

            [$detalles, $total] = $this->prepararDetalles($datos['detalles'], $pedido->id);

            foreach ($detalles as $det) {
                PedidoDetalle::create($det);
            }

            $updateData = [
                'cliente_id' => $datos['cliente_id'],
                'ruta_id' => $datos['ruta_id'] ?? null,
                'estado' => $datos['estado'],
                'comentario' => $datos['comentario'] ?? null,
                'total' => $total,
                'latitud' => $datos['latitud'] ?? null,
                'longitud' => $datos['longitud'] ?? null,
                'fecha_entrega' => $datos['fecha_entrega'] ?? null,
                'nota_produccion' => $datos['nota_produccion'] ?? null,
            ];

            if (array_key_exists('num_factura', $datos)) {
                $updateData['num_factura'] = $datos['num_factura'];
            }

            $pedido->update($updateData);

            if (in_array($originalEstado->value, ['borrador', 'cotizacion']) && $datos['estado'] === 'enviado') {
                $this->deducirInventario($pedido->load('detalles'));
            }

            return $pedido->load('detalles');
        });
    }

    public function cambiarEstado(Pedido $pedido, string $nuevoEstado, User $usuario, ?string $numFactura = null): Pedido
    {
        return DB::transaction(function () use ($pedido, $nuevoEstado, $usuario, $numFactura) {
            $estadoAnterior = $pedido->estado;

            if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                $pedido->facturador_id = $usuario->id;
            }

            if ($numFactura !== null) {
                $pedido->num_factura = $numFactura;
            }

            $pedido->estado = $nuevoEstado;
            $pedido->save();

            if ($estadoAnterior->value === 'borrador' && $nuevoEstado === 'enviado') {
                $this->deducirInventario($pedido->load('detalles'));
            }

            return $pedido;
        });
    }

    public function actualizarInformacionPrincipal(Pedido $pedido, array $datos, User $usuario): Pedido
    {
        return DB::transaction(function () use ($pedido, $datos, $usuario) {
            $estadoAnterior = $pedido->estado;

            if (array_key_exists('cliente_id', $datos) && !empty($datos['cliente_id'])) {
                $pedido->cliente_id = $datos['cliente_id'];
            }
            if (array_key_exists('ruta_id', $datos)) {
                $pedido->ruta_id = $datos['ruta_id'];
            }
            if (array_key_exists('vendedor_id', $datos) && !empty($datos['vendedor_id'])) {
                $pedido->vendedor_id = $datos['vendedor_id'];
            }
            if (array_key_exists('num_factura', $datos)) {
                $pedido->num_factura = $datos['num_factura'];
            }
            if (array_key_exists('fecha_entrega', $datos)) {
                $pedido->fecha_entrega = $datos['fecha_entrega'];
            }
            if (array_key_exists('comentario', $datos)) {
                $pedido->comentario = $datos['comentario'];
            }
            if (array_key_exists('nota_produccion', $datos)) {
                $pedido->nota_produccion = $datos['nota_produccion'];
            }

            if (!empty($datos['estado'])) {
                $nuevoEstado = is_string($datos['estado']) ? $datos['estado'] : (is_object($datos['estado']) ? $datos['estado']->value : strval($datos['estado']));
                $anteriorValor = is_string($estadoAnterior) ? $estadoAnterior : (is_object($estadoAnterior) ? $estadoAnterior->value : strval($estadoAnterior));
                
                if ($nuevoEstado !== $anteriorValor) {
                    if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                        $pedido->facturador_id = $usuario->id;
                    }
                    $pedido->estado = $nuevoEstado;

                    if ($anteriorValor === 'borrador' && $nuevoEstado === 'enviado') {
                        $this->deducirInventario($pedido->load('detalles'));
                    }
                }
            }

            $pedido->save();

            return $pedido->load([
                'cliente:id,nombre',
                'ruta:id,nombre',
                'vendedor:id,name',
                'facturador:id,name',
                'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
            ]);
        });
    }

    private function prepararDetalles(array $detallesEntrada, ?int $pedidoId = null): array
    {
        $detalles = [];
        $total = 0.0;

        foreach ($detallesEntrada as $detalle) {
            $producto = Producto::findOrFail($detalle['producto_id']);
            $precio = (float) $detalle['precio_unitario'];
            $cantidad = (float) $detalle['cantidad'];
            
            $subtotal = round($cantidad * $precio, 2);

            $stockActual = (float) $producto->stock;
            $cantidadSolicitada = $cantidad;
            $faltanteEstimado = max(0, $cantidadSolicitada - $stockActual);

            $detData = [
                'producto_id' => $producto->id,
                'cantidad' => $cantidad,
                'precio_unitario' => $precio,
                'subtotal' => $subtotal,
                'observacion' => $detalle['observacion'] ?? null,
                'cantidad_en_produccion' => $faltanteEstimado,
            ];

            if ($pedidoId) {
                $detData['pedido_id'] = $pedidoId;
            }

            $detalles[] = $detData;
            $total += $subtotal;
        }

        return [$detalles, round($total, 2)];
    }

    public function deducirInventario(Pedido $pedido)
    {
        $detallesFaltantes = [];

        foreach ($pedido->detalles as $detalle) {
            $producto = Producto::lockForUpdate()->find($detalle->producto_id);
            if ($producto) {
                $stockReal = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle->cantidad;
                
                $cantidadFaltante = max(0, $cantidadSolicitada - $stockReal);
                $cantidadAEntregar = $cantidadSolicitada - $cantidadFaltante;
                
                $detalle->update(['cantidad_en_produccion' => $cantidadFaltante]);

                if ($cantidadFaltante > 0) {
                    $detallesFaltantes[] = [
                        'producto_id'       => $detalle->producto_id,
                        'pedido_detalle_id' => $detalle->id,
                        'cantidad_faltante' => $cantidadFaltante,
                        'cantidad_producida' => 0,
                        'estado'            => 'pendiente',
                    ];
                }

                if ($cantidadAEntregar > 0) {
                    $stockResultante = $stockReal - $cantidadAEntregar;
                    $producto->update(['stock' => $stockResultante]);

                    InventarioMovimiento::create([
                        'producto_id'      => $producto->id,
                        'user_id'          => Auth::id(),
                        'tipo'             => 'VENTA',
                        'subtipo'          => 'VENTA A PEDIDO',
                        'cantidad'         => -$cantidadAEntregar,
                        'stock_anterior'   => $stockReal,
                        'stock_resultante' => $stockResultante,
                        'nota'             => "Pedido #{$pedido->id}",
                    ]);
                }
            }
        }

        if (count($detallesFaltantes) > 0) {
            $this->produccionService->crearOrdenPorFaltantes(
                $pedido->id, 
                $pedido->cliente_id, 
                $pedido->vendedor_id, 
                $detallesFaltantes, 
                $pedido->fecha_entrega, 
                $pedido->nota_produccion
            );
        }
    }

    private function esViolacionDeUnicidad(QueryException $e): bool
    {
        return in_array($e->getCode(), ['23505', '1062'], true);
    }
}