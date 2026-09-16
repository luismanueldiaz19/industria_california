<?php



// app/Modules/Pedido/Services/PedidoService.php
namespace App\Modules\Pedido\Services;

use App\Models\User;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Repositories\Contracts\PedidoRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PedidoService
{
    public function __construct(
        private readonly PedidoRepositoryInterface $pedidos,
    ) {}

    public function crear(array $datos, User $vendedor): Pedido
    {
        $idempotencyKey = $datos['idempotency_key'] ?? null;

        // Camino rápido: si ya existe, ni siquiera abrimos transacción.
        if ($idempotencyKey !== null) {
            $existente = $this->pedidos->buscarPorIdempotencyKey($idempotencyKey);
            if ($existente !== null) {
                return $existente;
            }
        }

        try {
            return DB::transaction(function () use ($datos, $vendedor, $idempotencyKey) {
                [$detalles, $total] = $this->prepararDetalles($datos['detalles']);

                return $this->pedidos->crear([
                    'cliente_id' => $datos['cliente_id'],
                    'ruta_id' => $datos['ruta_id'] ?? null,
                    'vendedor_id' => $vendedor->id,
                    'estado' => $datos['estado'],
                    'comentario' => $datos['comentario'] ?? null,
                    'total' => $total,
                    'latitud' => $datos['latitud'] ?? null,
                    'longitud' => $datos['longitud'] ?? null,
                    'idempotency_key' => $idempotencyKey,
                ], $detalles);
            });
        } catch (QueryException $e) {
            // Carrera: otro request con la misma clave ganó entre
            // el "camino rápido" de arriba y este intento de insertar.
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

    private function prepararDetalles(array $detallesEntrada): array
    {
        $detalles = [];
        $total = '0';

        foreach ($detallesEntrada as $detalle) {
            $cantidad = (string) $detalle['cantidad'];
            $precio = (string) $detalle['precio_unitario'];
            $subtotal = bcmul($cantidad, $precio, 2);

            $detalles[] = [
                'producto_id' => $detalle['producto_id'],
                'cantidad' => $cantidad,
                'precio_unitario' => $precio,
                'subtotal' => $subtotal,
                'observacion' => $detalle['observacion'] ?? null,
            ];

            $total = bcadd($total, $subtotal, 2);
        }

        return [$detalles, $total];
    }

    private function esViolacionDeUnicidad(QueryException $e): bool
    {
        // Postgres usa el código SQLSTATE '23505' para unique_violation.
        // MySQL usa '1062'. Cubrimos ambos por si algún día migras motor.
        return in_array($e->getCode(), ['23505', '1062'], true);
    }
}