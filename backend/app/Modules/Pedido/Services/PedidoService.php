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
use App\Modules\Produccion\Models\OrdenProduccionDetalle;

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

                if ($datos['estado'] === 'enviado' || $datos['estado'] === 'facturado') {
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
            $originalEstado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
            if ($originalEstado === 'entregado') {
                throw new \InvalidArgumentException('Un pedido ENTREGADO no puede ser modificado ya que finalizó su ciclo de despacho.');
            }

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

            if (in_array($originalEstado, ['borrador', 'cotizacion']) && $datos['estado'] === 'enviado') {
                $this->deducirInventario($pedido->load('detalles'));
            }

            return $pedido->load('detalles');
        });
    }

    public function cambiarEstado(Pedido $pedido, string $nuevoEstado, User $usuario, ?string $numFactura = null): Pedido
    {
        return DB::transaction(function () use ($pedido, $nuevoEstado, $usuario, $numFactura) {
            $estadoAnterior = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;

            if ($estadoAnterior === 'entregado' && $nuevoEstado !== 'entregado') {
                throw new \InvalidArgumentException('Un pedido ENTREGADO no puede cambiar a ningún otro estado ya que finalizó su ciclo de despacho.');
            }

            if ($estadoAnterior === 'facturado' && $nuevoEstado !== 'facturado') {
                throw new \InvalidArgumentException('Un pedido FACTURADO no puede cambiar a ningún otro estado.');
            }

            if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                $pedido->facturador_id = $usuario->id;
            }

            if ($numFactura !== null) {
                $pedido->num_factura = $numFactura;
            }

            $pedido->estado = $nuevoEstado;
            $pedido->save();

            // Si pasa de borrador o cotización a enviado o facturado -> deducir
            if (in_array($estadoAnterior, ['borrador', 'cotizacion'], true) && in_array($nuevoEstado, ['enviado', 'facturado'], true)) {
                $this->deducirInventario($pedido->load('detalles'));
            } 
            // Si pasa de enviado a borrador o cancelado -> restaurar inventario
            elseif ($estadoAnterior === 'enviado' && in_array($nuevoEstado, ['borrador', 'cancelado'], true)) {
                $this->restaurarInventario($pedido->load('detalles'));
            }

            return $pedido;
        });
    }

    public function actualizarInformacionPrincipal(Pedido $pedido, array $datos, User $usuario): Pedido
    {
        return DB::transaction(function () use ($pedido, $datos, $usuario) {
            $estadoAnterior = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
            if ($estadoAnterior === 'entregado') {
                throw new \InvalidArgumentException('Un pedido ENTREGADO no puede ser modificado ya que finalizó su ciclo de despacho.');
            }

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
                    if ($anteriorValor === 'facturado') {
                        throw new \InvalidArgumentException('Un pedido FACTURADO no puede cambiar a ningún otro estado.');
                    }

                    if ($nuevoEstado === 'facturado' || $nuevoEstado === 'cancelado') {
                        $pedido->facturador_id = $usuario->id;
                    }
                    $pedido->estado = $nuevoEstado;

                    // Si pasa de borrador o cotización a enviado o facturado -> deducir
                    if (in_array($anteriorValor, ['borrador', 'cotizacion'], true) && in_array($nuevoEstado, ['enviado', 'facturado'], true)) {
                        $this->deducirInventario($pedido->load('detalles'));
                    } 
                    // Si pasa de enviado a borrador o cancelado -> restaurar inventario
                    elseif ($anteriorValor === 'enviado' && in_array($nuevoEstado, ['borrador', 'cancelado'], true)) {
                        $this->restaurarInventario($pedido->load('detalles'));
                    }
                }
            }

            $pedido->save();

            return $pedido->load([
                'cliente:id,nombre',
                'ruta:id,nombre',
                'vendedor:id,name',
                'facturador:id,name',
                'ordenProduccion:id,pedido_id,estado',
                'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
            ]);
        });
    }

    public function facturarVigenteYEscindir(Pedido $pedido, array $datos, User $usuario): array
    {
        return DB::transaction(function () use ($pedido, $datos, $usuario) {
            $estadoActual = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
            if (in_array(strtolower($estadoActual), ['facturado', 'cancelado', 'entregado'], true)) {
                throw new \InvalidArgumentException("El pedido #{$pedido->id} ya se encuentra en estado '{$estadoActual}' y no puede ser facturado nuevamente.");
            }

            $detallesActuales = $pedido->detalles()->get();
            if ($detallesActuales->isEmpty()) {
                throw new \InvalidArgumentException("El pedido #{$pedido->id} no contiene artículos para facturar.");
            }

            $numFactura = $datos['num_factura'] ?? null;

            $tieneFaltantes = $detallesActuales->contains(function ($det) {
                return (float) $det->cantidad_en_produccion > 0;
            });

            // Si no tiene faltantes, simplemente se factura de forma normal
            if (!$tieneFaltantes) {
                $pedido->estado = 'facturado';
                $pedido->facturador_id = $usuario->id;
                if ($numFactura) {
                    $pedido->num_factura = $numFactura;
                }
                $pedido->save();

                return [
                    'pedido_facturado' => $pedido->load([
                        'cliente:id,nombre',
                        'ruta:id,nombre',
                        'vendedor:id,name',
                        'facturador:id,name',
                        'ordenProduccion:id,pedido_id,estado',
                        'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
                    ]),
                    'pedido_remanente' => null,
                ];
            }

            // Validar que exista inventario disponible para facturar (total vigente > 0)
            $totalVigenteCalculado = 0.0;
            foreach ($detallesActuales as $det) {
                $cantSolicitada = (float) $det->cantidad;
                $cantFaltante = (float) $det->cantidad_en_produccion;
                $cantVigente = max(0, $cantSolicitada - $cantFaltante);
                $totalVigenteCalculado += round($cantVigente * (float) $det->precio_unitario, 2);
            }

            if ($totalVigenteCalculado <= 0) {
                throw new \InvalidArgumentException("No es posible facturar lote vigente porque no hay artículos disponibles en inventario ($0.00 disponible). Todos los productos están pendientes de producción.");
            }

            // 1. Crear el nuevo Pedido Remanente para los faltantes
            $pedidoRemanente = Pedido::create([
                'cliente_id' => $pedido->cliente_id,
                'ruta_id' => $pedido->ruta_id,
                'vendedor_id' => $pedido->vendedor_id,
                'estado' => 'enviado',
                'comentario' => "Remanente generado por faltantes del Pedido #{$pedido->id}" . (!empty($datos['comentario']) ? " - " . $datos['comentario'] : ""),
                'fecha_entrega' => $datos['fecha_entrega'] ?? $pedido->fecha_entrega,
                'nota_produccion' => $datos['nota_produccion'] ?? $pedido->nota_produccion,
                'total' => 0.0,
            ]);

            $totalRemanente = 0.0;
            $totalVigente = 0.0;
            $detallesFaltantesParaNuevaOp = [];

            foreach ($detallesActuales as $det) {
                $cantSolicitada = (float) $det->cantidad;
                $cantFaltante = (float) $det->cantidad_en_produccion;
                $cantVigente = max(0, $cantSolicitada - $cantFaltante);
                $precio = (float) $det->precio_unitario;

                // Crear detalle en el pedido remanente si hay faltante
                if ($cantFaltante > 0) {
                    $subtotalFaltante = round($cantFaltante * $precio, 2);
                    $detRemanente = PedidoDetalle::create([
                        'pedido_id' => $pedidoRemanente->id,
                        'producto_id' => $det->producto_id,
                        'cantidad' => $cantFaltante,
                        'cantidad_en_produccion' => $cantFaltante,
                        'precio_unitario' => $precio,
                        'subtotal' => $subtotalFaltante,
                        'observacion' => "Faltante del Pedido #{$pedido->id}",
                    ]);
                    $totalRemanente += $subtotalFaltante;

                    // Re-vincular OrdenProduccionDetalle existente al nuevo detalle remanente
                    $opDetalles = OrdenProduccionDetalle::where('pedido_detalle_id', $det->id)->get();
                    if ($opDetalles->isNotEmpty()) {
                        foreach ($opDetalles as $opd) {
                            $opd->update(['pedido_detalle_id' => $detRemanente->id]);
                            $op = $opd->ordenProduccion;
                            if ($op && $op->pedido_id == $pedido->id) {
                                $op->update([
                                    'pedido_id' => $pedidoRemanente->id,
                                    'notas' => trim(($op->notas ?? '') . " (Vinculado a Pedido Remanente #{$pedidoRemanente->id})"),
                                ]);
                            }
                        }
                    } else {
                        $detallesFaltantesParaNuevaOp[] = [
                            'producto_id' => $det->producto_id,
                            'pedido_detalle_id' => $detRemanente->id,
                            'cantidad_faltante' => $cantFaltante,
                            'cantidad_producida' => 0,
                            'estado' => 'pendiente',
                        ];
                    }
                }

                // Actualizar o eliminar el detalle original en el pedido facturado
                if ($cantVigente > 0) {
                    $subtotalVigente = round($cantVigente * $precio, 2);
                    $det->update([
                        'cantidad' => $cantVigente,
                        'cantidad_en_produccion' => 0,
                        'subtotal' => $subtotalVigente,
                    ]);
                    $totalVigente += $subtotalVigente;
                } else {
                    $det->delete();
                }
            }

            // Si no existía OP para los faltantes, crearla ahora para el remanente
            if (!empty($detallesFaltantesParaNuevaOp)) {
                $this->produccionService->crearOrdenPorFaltantes(
                    $pedidoRemanente->id,
                    $pedidoRemanente->cliente_id,
                    $pedidoRemanente->vendedor_id,
                    $detallesFaltantesParaNuevaOp,
                    $pedidoRemanente->fecha_entrega,
                    $pedidoRemanente->nota_produccion
                );
            }

            // Actualizar total y estado del pedido facturado
            $pedido->total = $totalVigente;
            $pedido->estado = 'facturado';
            $pedido->facturador_id = $usuario->id;
            if ($numFactura) {
                $pedido->num_factura = $numFactura;
            }
            $notaEscision = "Facturado lote disponible ($" . number_format($totalVigente, 2) . "). Faltante escindido a Pedido #{$pedidoRemanente->id}";
            $pedido->comentario = $pedido->comentario ? ($pedido->comentario . " | " . $notaEscision) : $notaEscision;
            $pedido->save();

            // Actualizar total del pedido remanente
            $pedidoRemanente->update(['total' => $totalRemanente]);

            return [
                'pedido_facturado' => $pedido->load([
                    'cliente:id,nombre',
                    'ruta:id,nombre',
                    'vendedor:id,name',
                    'facturador:id,name',
                    'ordenProduccion:id,pedido_id,estado',
                    'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
                ]),
                'pedido_remanente' => $pedidoRemanente->load([
                    'cliente:id,nombre',
                    'ruta:id,nombre',
                    'vendedor:id,name',
                    'ordenProduccion:id,pedido_id,estado',
                    'detalles.producto:id,codigo,descripcion,imagen_producto,unidad,medidas,capacidad'
                ]),
            ];
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
        foreach ($pedido->detalles as $detalle) {
            $producto = Producto::lockForUpdate()->find($detalle->producto_id);
            if ($producto) {
                $stockReal = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle->cantidad;
                
                $cantidadFaltante = max(0, $cantidadSolicitada - $stockReal);
                $cantidadAEntregar = $cantidadSolicitada - $cantidadFaltante;
                
                $detalle->update(['cantidad_en_produccion' => $cantidadFaltante]);

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
    }

    public function restaurarInventario(Pedido $pedido)
    {
        foreach ($pedido->detalles as $detalle) {
            $producto = Producto::lockForUpdate()->find($detalle->producto_id);
            if ($producto) {
                $stockReal = (float) $producto->stock;
                $cantidadSolicitada = (float) $detalle->cantidad;
                $cantidadFaltante = (float) $detalle->cantidad_en_produccion;
                $cantidadEntregada = max(0, $cantidadSolicitada - $cantidadFaltante);

                if ($cantidadEntregada > 0) {
                    $stockResultante = $stockReal + $cantidadEntregada;
                    $producto->update(['stock' => $stockResultante]);

                    InventarioMovimiento::create([
                        'producto_id'      => $producto->id,
                        'user_id'          => Auth::id(),
                        'tipo'             => 'ENTRADA',
                        'subtipo'          => 'RETORNO INVENTARIO',
                        'cantidad'         => $cantidadEntregada,
                        'stock_anterior'   => $stockReal,
                        'stock_resultante' => $stockResultante,
                        'nota'             => "Retorno de inventario Pedido #{$pedido->id} (cambio a borrador o cancelado)",
                    ]);
                }

                $detalle->update(['cantidad_en_produccion' => 0]);
            }
        }
    }

    private function esViolacionDeUnicidad(QueryException $e): bool
    {
        return in_array($e->getCode(), ['23505', '1062'], true);
    }
}