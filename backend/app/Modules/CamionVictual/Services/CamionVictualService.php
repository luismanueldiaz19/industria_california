<?php

namespace App\Modules\CamionVictual\Services;

use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoCamion;
use App\Modules\CamionVictual\Enums\EstadoEntrega;
use App\Modules\CamionVictual\Models\CamionVictual;
use App\Modules\Pedido\Models\Pedido;
use Illuminate\Support\Facades\DB;

class CamionVictualService
{
    // Máximo de slots por chofer
    const MAX_SLOTS = 4;

    /**
     * Obtener el monto mínimo configurado en el sistema.
     */
    public function getMontoMinimo(): float
    {
        $config = DB::table('configuracion_sistema')
            ->where('clave', 'camion_victual_monto_minimo')
            ->value('valor');

        return (float) ($config ?? 300000.00);
    }

    /**
     * Crear un nuevo camión victual para un chofer.
     * El vendedor que lo crea se convierte en el responsable de llenarlo.
     *
     * @throws \Exception si el chofer ya tiene MAX_SLOTS camiones activos
     */
    public function crear(array $datos, User $vendedor): CamionVictual
    {
        $chofer_id = $datos['chofer_id'];

        $maxSlot = CamionVictual::where('chofer_id', $chofer_id)->max('slot_numero') ?? 0;
        $slotDisponible = $maxSlot + 1;

        return CamionVictual::create([
            'chofer_id'   => $chofer_id,
            'vendedor_id' => $datos['vendedor_id'] ?? $vendedor->id,
            'nombre'      => $datos['nombre'] ?? "Camión {$slotDisponible}",
            'slot_numero' => $slotDisponible,
            'estado'      => EstadoCamion::Vacio,
            'monto_total' => 0,
            'minimo_salida' => $datos['minimo_salida'] ?? 5000.00,
            'notas'       => $datos['notas'] ?? null,
        ]);
    }

    /**
     * Actualizar los datos de un camión victual.
     */
    public function actualizar(CamionVictual $camion, array $datos): CamionVictual
    {
        if (isset($datos['estado'])) {
            $datos['estado'] = EstadoCamion::from($datos['estado']);
        }

        $camion->update($datos);
        return $camion;
    }

    /**
     * Eliminar un camión victual.
     * Verifica que no tenga pedidos asignados.
     */
    public function eliminar(CamionVictual $camion): void
    {
        if ($camion->pedidos()->count() > 0) {
            throw new \Exception("No se puede eliminar el camión porque tiene pedidos asignados.");
        }
        $camion->delete();
    }

    /**
     * Agregar un pedido al camión victual.
     * Solo pedidos en estado 'facturado' y que no estén en otro camión activo.
     *
     * @throws \Exception si el pedido no cumple las condiciones
     */
    public function agregarPedido(CamionVictual $camion, int $pedidoId, User $vendedor): CamionVictual
    {
        if (!$camion->puedeModificarPedidos()) {
            throw new \Exception("No se pueden agregar pedidos. El camión está en estado '{$camion->estado->value}'.");
        }

        $pedido = Pedido::findOrFail($pedidoId);

        // Solo pedidos facturados
        if ($pedido->estado->value !== 'facturado') {
            throw new \Exception("Solo se pueden agregar pedidos en estado 'facturado'. Este pedido está en '{$pedido->estado->value}'.");
        }

        // Verificar que el pedido no esté ya en otro camión activo
        $enOtroCamion = DB::table('camion_victual_pedido')
            ->join('camiones_victuales', 'camiones_victuales.id', '=', 'camion_victual_pedido.camion_victual_id')
            ->where('camion_victual_pedido.pedido_id', $pedidoId)
            ->whereIn('camiones_victuales.estado', ['armando', 'listo', 'en_ruta'])
            ->exists();

        if ($enOtroCamion) {
            throw new \Exception("Este pedido ya está asignado a otro camión activo.");
        }

        return DB::transaction(function () use ($camion, $pedido) {
            // Determinar el siguiente orden de viaje
            $maxOrden = $camion->pedidos()->max('camion_victual_pedido.orden_viaje') ?? 0;

            $camion->pedidos()->attach($pedido->id, [
                'orden_viaje'    => $maxOrden + 1,
                'estado_entrega' => EstadoEntrega::Pendiente->value,
            ]);

            if ($camion->estado === EstadoCamion::Vacio) {
                $camion->estado = EstadoCamion::Armando;
                $camion->save();
            }

            return $this->recalcularMonto($camion);
        });
    }

    /**
     * Quitar un pedido del camión victual.
     *
     * @throws \Exception si el camión no está en estado 'armando'
     */
    public function quitarPedido(CamionVictual $camion, int $pedidoId): CamionVictual
    {
        if (!$camion->puedeModificarPedidos()) {
            throw new \Exception("No se pueden quitar pedidos. El camión está en estado '{$camion->estado->value}'.");
        }

        return DB::transaction(function () use ($camion, $pedidoId) {
            $camion->pedidos()->detach($pedidoId);

            // Re-numerar el orden_viaje para que no queden huecos
            $this->renumerarOrden($camion);

            return $this->recalcularMonto($camion);
        });
    }

    /**
     * Reordenar los pedidos del camión.
     * Recibe un array con la nueva secuencia: [['pedido_id' => 1, 'orden_viaje' => 1], ...]
     *
     * @throws \Exception si el camión no está en estado 'armando'
     */
    public function reordenarPedidos(CamionVictual $camion, array $ordenNuevo): CamionVictual
    {
        if (!$camion->puedeModificarPedidos()) {
            throw new \Exception("No se puede reordenar. El camión está en estado '{$camion->estado->value}'.");
        }

        DB::transaction(function () use ($camion, $ordenNuevo) {
            foreach ($ordenNuevo as $item) {
                DB::table('camion_victual_pedido')
                    ->where('camion_victual_id', $camion->id)
                    ->where('pedido_id', $item['pedido_id'])
                    ->update(['orden_viaje' => $item['orden_viaje']]);
            }
        });

        return $this->cargarRelaciones($camion);
    }

    /**
     * Logística marca un pedido como en_curso o entregado o fallido.
     */
    public function actualizarEstadoEntrega(
        CamionVictual $camion,
        int $pedidoId,
        EstadoEntrega $nuevoEstado,
        ?string $comentario = null
    ): CamionVictual {
        $fechaEntregado = $nuevoEstado === EstadoEntrega::Entregado ? now() : null;

        DB::table('camion_victual_pedido')
            ->where('camion_victual_id', $camion->id)
            ->where('pedido_id', $pedidoId)
            ->update([
                'estado_entrega'   => $nuevoEstado->value,
                'comentario_entrega' => $comentario,
                'fecha_entregado'  => $fechaEntregado,
                'updated_at'       => now(),
            ]);

        // Verificar si todos los pedidos están terminados para poder cerrar
        $camionActualizado = $camion->fresh('pedidos');
        $this->verificarCierreAutomatico($camionActualizado);

        return $this->cargarRelaciones($camionActualizado);
    }

    /**
     * Logística pone el camión en_ruta (sale a logística).
     * Solo posible si el camión está en estado 'listo'.
     */
    public function ponerEnRuta(CamionVictual $camion): CamionVictual
    {
        if ($camion->estado !== EstadoCamion::Listo) {
            throw new \Exception("Solo camiones en estado 'listo' pueden salir a ruta. Estado actual: '{$camion->estado->value}'.");
        }

        $camion->update(['estado' => EstadoCamion::EnRuta]);

        return $camion->fresh();
    }

    /**
     * Cerrar el camión manualmente desde logística.
     */
    public function cerrar(CamionVictual $camion, User $responsable): CamionVictual
    {
        if ($camion->estado === EstadoCamion::Cerrado) {
            throw new \Exception("El camión ya está cerrado.");
        }

        $camion->update([
            'estado'       => EstadoCamion::Cerrado,
            'fecha_cierre' => now(),
            'cerrado_por'  => $responsable->id,
        ]);

        return $camion->fresh();
    }

    // ─── Helpers privados ─────────────────────────────────────────

    /**
     * Recalcular el monto total del camión y actualizar el estado automáticamente.
     */
    private function recalcularMonto(CamionVictual $camion): CamionVictual
    {
        $total = $camion->pedidos()->sum('pedidos.total');

        $datosUpdate = ['monto_total' => $total];

        // Solo actualizar estado si está vacío y recibe pedidos, o si se vacía.
        // El vendedor es quien decide manualmente cuándo ponerlo en 'listo'.
        if ($total > 0 && $camion->estado === EstadoCamion::Vacio) {
            $datosUpdate['estado'] = EstadoCamion::Armando;
        } elseif ($total == 0 && $camion->estado === EstadoCamion::Armando) {
            $datosUpdate['estado'] = EstadoCamion::Vacio;
        }

        $camion->update($datosUpdate);

        return $this->cargarRelaciones($camion);
    }

    /**
     * Helper para recargar el camión con todas las relaciones necesarias para el frontend.
     */
    private function cargarRelaciones(CamionVictual $camion): CamionVictual
    {
        return $camion->fresh([
            'chofer.user:id,name',
            'vendedor:id,name',
            'pedidos' => function ($q) {
                $q->with('cliente:id,nombre,direccion')
                  ->orderByPivot('orden_viaje', 'asc');
            },
        ]);
    }

    /**
     * Re-numerar orden_viaje tras quitar un pedido, para mantener secuencia 1,2,3...
     */
    private function renumerarOrden(CamionVictual $camion): void
    {
        $pedidos = DB::table('camion_victual_pedido')
            ->where('camion_victual_id', $camion->id)
            ->orderBy('orden_viaje')
            ->pluck('pedido_id');

        foreach ($pedidos as $index => $pedidoId) {
            DB::table('camion_victual_pedido')
                ->where('camion_victual_id', $camion->id)
                ->where('pedido_id', $pedidoId)
                ->update(['orden_viaje' => $index + 1]);
        }
    }

    /**
     * Si todos los pedidos del camión están entregados o fallidos, cerrar automáticamente.
     */
    private function verificarCierreAutomatico(CamionVictual $camion): void
    {
        if ($camion->estado !== EstadoCamion::EnRuta) {
            return;
        }

        $pendientes = DB::table('camion_victual_pedido')
            ->where('camion_victual_id', $camion->id)
            ->whereIn('estado_entrega', ['pendiente', 'en_curso'])
            ->count();

        if ($pendientes === 0 && $camion->pedidos()->count() > 0) {
            $camion->update([
                'estado'       => EstadoCamion::Cerrado,
                'fecha_cierre' => now(),
            ]);
        }
    }
}
