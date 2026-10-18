<?php

namespace App\Modules\CamionVictual\Services;

use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoCamion;
use App\Modules\CamionVictual\Enums\EstadoEntrega;
use App\Modules\CamionVictual\Enums\EstadoViaje;
use App\Modules\CamionVictual\Enums\TipoGastoViaje;
use App\Modules\CamionVictual\Models\CamionVictual;
use App\Modules\CamionVictual\Models\CamionViaje;
use App\Modules\CamionVictual\Models\CamionViajePedido;
use App\Modules\CamionVictual\Models\CamionViajeGasto;
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

        return (float) ($config ?? 500000.00);
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
            'minimo_salida' => $datos['minimo_salida'] ?? $this->getMontoMinimo(),
            'notas'       => $datos['notas'] ?? null,
        ]);
    }

    /**
     * Actualizar los datos de un camión victual.
     */
    public function actualizar(CamionVictual $camion, array $datos): CamionVictual
    {
        if (isset($datos['estado'])) {
            $nuevoEstado = EstadoCamion::from($datos['estado']);
            if ($nuevoEstado === EstadoCamion::Listo) {
                $minimo = ($camion->minimo_salida > 5000.0) ? (float)$camion->minimo_salida : $this->getMontoMinimo();
                if ((float)$camion->monto_total < $minimo) {
                    throw new \Exception("No se puede marcar como 'listo'. El monto cargado (RD$ " . number_format($camion->monto_total, 2) . ") no alcanza el mínimo requerido (RD$ " . number_format($minimo, 2) . ").");
                }
            }
            $datos['estado'] = $nuevoEstado;
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

        // Verificar que el pedido no esté ya asignado a un camión
        $yaAsignado = DB::table('camion_victual_pedido')
            ->where('pedido_id', $pedidoId)
            ->exists();

        if ($yaAsignado) {
            throw new \Exception("Este pedido ya está asignado a un camión.");
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

        if ($nuevoEstado === EstadoEntrega::Entregado) {
            DB::table('pedidos')
                ->where('id', $pedidoId)
                ->update([
                    'estado' => 'entregado',
                    'updated_at' => now(),
                ]);
        }

        // Sincronizar con el viaje activo si existe
        $viajeActivo = CamionViaje::where('camion_victual_id', $camion->id)
            ->where('estado', EstadoViaje::EnRuta)
            ->latest()
            ->first();

        if ($viajeActivo) {
            CamionViajePedido::where('viaje_id', $viajeActivo->id)
                ->where('pedido_id', $pedidoId)
                ->update([
                    'estado_entrega'     => $nuevoEstado->value,
                    'comentario_entrega' => $comentario,
                    'fecha_entregado'    => $fechaEntregado,
                    'updated_at'         => now(),
                ]);
        }

        // Verificar si todos los pedidos están terminados para poder cerrar
        $camionActualizado = $camion->fresh('pedidos');
        $this->verificarCierreAutomatico($camionActualizado);

        return $this->cargarRelaciones($camionActualizado);
    }

    /**
     * Logística pone el camión en_ruta (sale a logística).
     * Solo posible si el camión está en estado 'listo' o 'armando'.
     * Pone automáticamente todos sus pedidos asignados en estado 'en_curso'
     * y genera automáticamente un nuevo registro de Viaje Histórico (ej: VJ-0001).
     */
    public function ponerEnRuta(CamionVictual $camion): CamionVictual
    {
        if ($camion->estado !== EstadoCamion::Listo && $camion->estado !== EstadoCamion::Armando) {
            throw new \Exception("Solo camiones en estado 'listo' o 'armando' pueden salir a ruta. Estado actual: '{$camion->estado->value}'.");
        }

        DB::transaction(function () use ($camion) {
            $camion->update(['estado' => EstadoCamion::EnRuta]);

            // Actualiza todos los pedidos asignados a este camión a 'en_curso' (excepto los ya entregados)
            DB::table('camion_victual_pedido')
                ->where('camion_victual_id', $camion->id)
                ->where('estado_entrega', '!=', EstadoEntrega::Entregado->value)
                ->update([
                    'estado_entrega'   => EstadoEntrega::EnCurso->value,
                    'fecha_entregado'  => null,
                    'updated_at'       => now(),
                ]);

            // Generar correlativo amigable VJ-0001
            $count = CamionViaje::count() + 1;
            $codigo = 'VJ-' . str_pad($count, 4, '0', STR_PAD_LEFT);

            // Crear el registro del Viaje en ruta
            $viaje = CamionViaje::create([
                'codigo'            => $codigo,
                'camion_victual_id' => $camion->id,
                'chofer_id'         => $camion->chofer_id,
                'vendedor_id'       => $camion->vendedor_id,
                'fecha_salida'      => now(),
                'total_facturado'   => $camion->monto_total,
                'total_gastos'      => 0,
                'cant_ayudantes'    => 0,
                'estado'            => EstadoViaje::EnRuta,
            ]);

            // Copiar los pedidos asignados al viaje histórico
            $pedidos = $camion->pedidos()->get();
            foreach ($pedidos as $p) {
                CamionViajePedido::create([
                    'viaje_id'           => $viaje->id,
                    'pedido_id'          => $p->id,
                    'orden_viaje'        => $p->pivot->orden_viaje ?? 0,
                    'estado_entrega'     => EstadoEntrega::EnCurso,
                    'fecha_entregado'    => null,
                    'comentario_entrega' => $p->pivot->comentario_entrega ?? null,
                    'total_pedido'       => $p->total,
                ]);
            }
        });

        return $this->cargarRelaciones($camion->fresh());
    }

    /**
     * Cerrar el camión manualmente con o sin datos de liquidación.
     */
    public function cerrar(CamionVictual $camion, User $responsable): CamionVictual
    {
        $res = $this->cerrarConLiquidacion($camion, [], $responsable);
        return $res['camion'];
    }

    /**
     * Cierra el viaje liquidando gastos (combustible, dieta, etc.), ayudantes y comentarios.
     * Guarda el historial de forma permanente y LIBERA el camión dejándolo en VACÍO ($0.00).
     */
    public function cerrarConLiquidacion(CamionVictual $camion, array $datos, User $responsable): array
    {
        return DB::transaction(function () use ($camion, $datos, $responsable) {
            // 1. Localizar el viaje activo en ruta o crear uno para archivar
            $viaje = CamionViaje::where('camion_victual_id', $camion->id)
                ->where('estado', EstadoViaje::EnRuta)
                ->latest()
                ->first();

            if (!$viaje) {
                $count = CamionViaje::count() + 1;
                $viaje = CamionViaje::create([
                    'codigo'            => 'VJ-' . str_pad($count, 4, '0', STR_PAD_LEFT),
                    'camion_victual_id' => $camion->id,
                    'chofer_id'         => $camion->chofer_id,
                    'vendedor_id'       => $camion->vendedor_id,
                    'fecha_salida'      => $camion->updated_at ?? now(),
                    'total_facturado'   => $camion->monto_total,
                    'total_gastos'      => 0,
                    'cant_ayudantes'    => 0,
                    'estado'            => EstadoViaje::EnRuta,
                ]);
            }

            // 2. Registrar los gastos del viaje (combustible, dieta, peajes, etc.)
            $totalGastos = 0;
            if (!empty($datos['gastos']) && is_array($datos['gastos'])) {
                foreach ($datos['gastos'] as $g) {
                    $monto = (float) ($g['monto_total'] ?? 0);
                    if ($monto <= 0 && !empty($g['cantidad']) && !empty($g['precio_unitario'])) {
                        $monto = (float) $g['cantidad'] * (float) $g['precio_unitario'];
                    }
                    $totalGastos += $monto;

                    CamionViajeGasto::create([
                        'viaje_id'        => $viaje->id,
                        'tipo_gasto'      => $g['tipo_gasto'] ?? 'otro',
                        'concepto'        => $g['concepto'] ?? ucfirst($g['tipo_gasto'] ?? 'Gasto de viaje'),
                        'cantidad'        => $g['cantidad'] ?? 0,
                        'precio_unitario' => $g['precio_unitario'] ?? 0,
                        'monto_total'     => $monto,
                        'comprobante'     => $g['comprobante'] ?? null,
                        'registrado_por'  => $responsable->id,
                    ]);
                }
            }

            // 3. Sincronizar estados finales de los pedidos en el viaje
            $pedidosCamion = DB::table('camion_victual_pedido')
                ->where('camion_victual_id', $camion->id)
                ->get();

            foreach ($pedidosCamion as $pc) {
                CamionViajePedido::updateOrCreate(
                    ['viaje_id' => $viaje->id, 'pedido_id' => $pc->pedido_id],
                    [
                        'orden_viaje'        => $pc->orden_viaje,
                        'estado_entrega'     => $pc->estado_entrega,
                        'fecha_entregado'    => $pc->fecha_entregado,
                        'comentario_entrega' => $pc->comentario_entrega,
                    ]
                );
            }

            // 4. Completar y cerrar el viaje histórico
            $viaje->update([
                'cant_ayudantes'    => (int) ($datos['cant_ayudantes'] ?? 0),
                'nombres_ayudantes' => $datos['nombres_ayudantes'] ?? null,
                'comentarios'       => $datos['comentarios'] ?? null,
                'total_gastos'      => $totalGastos,
                'fecha_cierre'      => now(),
                'cerrado_por'       => $responsable->id,
                'estado'            => EstadoViaje::Completado,
            ]);

            // 5. LIBERAR EL CAMIÓN: desvincular pedidos y volverlo a estado VACÍO con $0.00
            $camion->pedidos()->detach();
            $camion->update([
                'estado'       => EstadoCamion::Vacio,
                'monto_total'  => 0.00,
                'fecha_cierre' => now(),
                'cerrado_por'  => $responsable->id,
            ]);

            return [
                'camion' => $this->cargarRelaciones($camion->fresh()),
                'viaje'  => $viaje->fresh(['gastos', 'pedidos.pedido.cliente', 'chofer.user', 'vendedor', 'cerradoPor']),
            ];
        });
    }

    /**
     * Obtener listado de viajes históricos con filtros.
     */
    public function getHistorialViajes(array $filtros = []): array
    {
        $query = CamionViaje::with([
            'chofer.user:id,name',
            'vendedor:id,name',
            'cerradoPor:id,name',
            'gastos',
            'pedidos.pedido.cliente:id,nombre',
        ])->orderBy('id', 'desc');

        if (!empty($filtros['chofer_id'])) {
            $query->where('chofer_id', $filtros['chofer_id']);
        }

        if (!empty($filtros['estado'])) {
            $query->where('estado', $filtros['estado']);
        }

        if (!empty($filtros['fecha_inicio']) && !empty($filtros['fecha_fin'])) {
            $query->whereBetween('fecha_salida', [$filtros['fecha_inicio'], $filtros['fecha_fin']]);
        }

        $perPage = (int) ($filtros['per_page'] ?? 30);
        $paginator = $query->paginate($perPage);

        return [
            'data'         => $paginator->items(),
            'total'        => $paginator->total(),
            'current_page' => $paginator->currentPage(),
            'last_page'    => $paginator->lastPage(),
        ];
    }

    /**
     * Obtener el detalle completo de un viaje específico.
     */
    public function getDetalleViaje(int $viajeId): CamionViaje
    {
        return CamionViaje::with([
            'chofer.user:id,name',
            'vendedor:id,name',
            'cerradoPor:id,name',
            'gastos',
            'pedidos.pedido.cliente:id,nombre,direccion',
            'pedidos.pedido.detalles.producto',
        ])->findOrFail($viajeId);
    }

    // ─── Helpers privados ─────────────────────────────────────────

    /**
     * Recalcular el monto total del camión y actualizar el estado automáticamente.
     */
    public function vaciar(CamionVictual $camion): CamionVictual
    {
        return DB::transaction(function () use ($camion) {
            $camion->pedidos()->detach();
            $camion->update([
                'estado' => EstadoCamion::Vacio,
                'monto_total' => 0.00
            ]);
            return $this->cargarRelaciones($camion->fresh());
        });
    }

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
