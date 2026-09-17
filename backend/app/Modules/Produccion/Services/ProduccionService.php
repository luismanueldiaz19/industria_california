<?php

namespace App\Modules\Produccion\Services;

use App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface;
use App\Modules\Produccion\Models\OrdenProduccion;

class ProduccionService
{
    public function __construct(
        private readonly ProduccionRepositoryInterface $produccionRepository
    ) {}

    public function crearOrdenPorFaltantes(int $pedidoId, int $clienteId, int $vendedorId, array $detallesFaltantes, ?string $fechaEntrega, ?string $notaProduccion): ?OrdenProduccion
    {
        if (empty($detallesFaltantes)) {
            return null;
        }

        $notaExtra = $notaProduccion ? "\nNota de vendedor: {$notaProduccion}" : '';
        
        $datosOrden = [
            'pedido_id'   => $pedidoId,
            'cliente_id'  => $clienteId,
            'vendedor_id' => $vendedorId,
            'estado'      => 'pendiente',
            'fecha_estimada_entrega' => $fechaEntrega,
            'notas'       => "Orden automática generada por faltantes del Pedido #{$pedidoId}{$notaExtra}",
        ];

        return $this->produccionRepository->crearOrdenAutomatica($datosOrden, $detallesFaltantes);
    }
}
