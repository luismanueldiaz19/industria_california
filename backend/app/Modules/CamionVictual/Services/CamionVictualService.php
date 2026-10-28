<?php

namespace App\Modules\CamionVictual\Services;

use App\Models\Chofer;
use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoCamion;
use App\Modules\CamionVictual\Enums\EstadoEntrega;
use App\Modules\CamionVictual\Enums\EstadoViaje;
use App\Modules\CamionVictual\Enums\TipoGastoViaje;
use App\Modules\CamionVictual\Models\CamionVictual;
use App\Modules\CamionVictual\Models\CamionViaje;
use App\Modules\CamionVictual\Models\CamionViajePedido;
use App\Modules\Vehiculo\Models\VehiculoGasto;
use App\Modules\Pedido\Models\Pedido;
use App\Modules\Vehiculo\Models\Vehiculo;
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

        return (float) ($config ?? 5000.00);
    }

    /**
     * Obtener el monto mínimo de salida para un camión específico.
     * Prioriza el minimo_salida del camión si es mayor a 0; de lo contrario, usa la configuración global.
     */
    public function getMinimoSalidaCamion(CamionVictual $camion): float
    {
        if ((float) $camion->minimo_salida > 0) {
            return (float) $camion->minimo_salida;
        }

        return $this->getMontoMinimo();
    }

    /**
     * Obtener el ID del chofer virtual por defecto.
     */
    public function getChoferVictualId(): int
    {
        $chofer = Chofer::where('numero_licencia', 'victual')
            ->orWhereHas('user', fn($q) => $q->where('username', 'victual')->orWhere('name', 'ilike', '%victual%'))
            ->first();

        return $chofer ? (int) $chofer->id : 1;
    }

    /**
     * Verificar si un chofer corresponde al chofer virtual.
     */
    public function esChoferVictual(int $choferId): bool
    {
        $victualId = $this->getChoferVictualId();
        if ($choferId === $victualId) {
            return true;
        }

        $chofer = Chofer::with('user')->find($choferId);
        if (!$chofer) {
            return false;
        }

        $lic = strtolower($chofer->numero_licencia ?? '');
        $username = strtolower($chofer->user?->username ?? '');
        $name = strtolower($chofer->user?->name ?? '');

        return str_contains($lic, 'victual') || str_contains($username, 'victual') || str_contains($name, 'victual');
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
            if ($nuevoEstado === EstadoCamion::Listo || $nuevoEstado === EstadoCamion::EnRuta) {
                // 1. Debe tener pedidos asignados
                if ($camion->pedidos()->count() === 0 || (float) $camion->monto_total <= 0) {
                    throw new \Exception("No se puede cambiar el estado a '{$nuevoEstado->value}'. El camión no tiene pedidos asignados.");
                }

                // 2. Debe cumplir con el mínimo requerido
                $minimo = $this->getMinimoSalidaCamion($camion);
                if ((float) $camion->monto_total < $minimo) {
                    $falta = $minimo - (float) $camion->monto_total;
                    throw new \Exception("No se puede cambiar el estado a '{$nuevoEstado->value}'. El monto cargado (RD$ " . number_format($camion->monto_total, 2) . ") no alcanza el mínimo requerido (RD$ " . number_format($minimo, 2) . "). Faltan RD$ " . number_format($falta, 2) . ".");
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
     * Es OBLIGATORIO asignar un vehículo físico real y un conductor real (no virtual).
     * Pone automáticamente todos sus pedidos asignados en estado 'en_curso'
     * y genera automáticamente un nuevo registro de Viaje Histórico (ej: VJ-0001).
     */
    public function ponerEnRuta(CamionVictual $camion, array $datos = []): CamionVictual
    {
        if ($camion->estado !== EstadoCamion::Listo && $camion->estado !== EstadoCamion::Armando) {
            throw new \Exception("Solo camiones en estado 'listo' o 'armando' pueden salir a ruta. Estado actual: '{$camion->estado->value}'.");
        }

        // 1. Debe tener pedidos asignados
        if ($camion->pedidos()->count() === 0 || (float) $camion->monto_total <= 0) {
            throw new \Exception("No se puede despachar el camión porque no tiene pedidos asignados.");
        }

        // 2. Debe cumplir con el monto mínimo de salida
        $minimo = $this->getMinimoSalidaCamion($camion);
        if ((float) $camion->monto_total < $minimo) {
            $falta = $minimo - (float) $camion->monto_total;
            throw new \Exception("No se puede despachar el camión. El monto cargado (RD$ " . number_format($camion->monto_total, 2) . ") no alcanza el mínimo de salida requerido (RD$ " . number_format($minimo, 2) . "). Faltan RD$ " . number_format($falta, 2) . ".");
        }

        // 3. Obligatorio: Asignar vehículo físico real
        $vehiculoId = (int) ($datos['vehiculo_id'] ?? $camion->vehiculo_id ?? 0);
        if ($vehiculoId <= 0) {
            throw new \Exception("Es obligatorio asignar un vehículo físico real para despachar el viaje a ruta.");
        }
        $vehiculo = Vehiculo::find($vehiculoId);
        if (!$vehiculo) {
            throw new \Exception("El vehículo seleccionado no existe.");
        }
        if ($vehiculo->estado === 'inactivo') {
            throw new \Exception("El vehículo {$vehiculo->ficha} se encuentra inactivo y no puede despacharse.");
        }
        $vehiculoEnUso = CamionVictual::where('estado', EstadoCamion::EnRuta)
            ->where('vehiculo_id', $vehiculoId)
            ->where('id', '!=', $camion->id)
            ->exists();
        if ($vehiculoEnUso) {
            throw new \Exception("El vehículo {$vehiculo->ficha} ya se encuentra asignado y en ruta en otro camión.");
        }

        // 4. Obligatorio: Asignar chofer real (no puede ser el chofer virtual)
        $choferId = (int) ($datos['chofer_id'] ?? $camion->chofer_id ?? 0);
        if ($choferId <= 0) {
            throw new \Exception("Es obligatorio asignar un conductor real para despachar el viaje.");
        }
        if ($this->esChoferVictual($choferId)) {
            throw new \Exception("Debe asignar un conductor real para despachar el viaje. No se permite despachar con el chofer virtual.");
        }
        $chofer = Chofer::with('user')->find($choferId);
        if (!$chofer) {
            throw new \Exception("El conductor seleccionado no existe.");
        }
        if ($chofer->estado !== 'activo') {
            throw new \Exception("El conductor seleccionado no se encuentra activo.");
        }
        $choferEnUso = CamionVictual::where('estado', EstadoCamion::EnRuta)
            ->where('chofer_id', $choferId)
            ->where('id', '!=', $camion->id)
            ->exists();
        if ($choferEnUso) {
            $nombreChofer = $chofer->user?->name ?? 'seleccionado';
            throw new \Exception("El conductor {$nombreChofer} ya se encuentra en ruta en otro camión.");
        }

        DB::transaction(function () use ($camion, $vehiculoId, $choferId, $datos) {
            $camion->update([
                'estado'      => EstadoCamion::EnRuta,
                'vehiculo_id' => $vehiculoId,
                'chofer_id'   => $choferId,
            ]);

            // Actualiza todos los pedidos asignados a este camión a 'en_curso' (excepto los ya entregados)
            DB::table('camion_victual_pedido')
                ->where('camion_victual_id', $camion->id)
                ->where('estado_entrega', '!=', EstadoEntrega::Entregado->value)
                ->update([
                    'estado_entrega'   => EstadoEntrega::EnCurso->value,
                    'fecha_entregado'  => null,
                    'updated_at'       => now(),
                ]);

            // Localizar viaje previo si ya existía (guardado preliminarmente) o crear uno nuevo
            $viaje = CamionViaje::where('camion_victual_id', $camion->id)
                ->where('estado', EstadoViaje::EnRuta)
                ->latest()
                ->first();

            if (!$viaje) {
                $codigo = CamionViaje::generarSiguienteCodigo();
                $viaje = CamionViaje::create([
                    'codigo'            => $codigo,
                    'camion_victual_id' => $camion->id,
                    'chofer_id'         => $choferId,
                    'vehiculo_id'       => $vehiculoId,
                    'vendedor_id'       => $camion->vendedor_id,
                    'fecha_salida'      => now(),
                    'total_facturado'   => $camion->monto_total,
                    'total_gastos'      => 0,
                    'cant_ayudantes'    => (int) ($datos['cant_ayudantes'] ?? 0),
                    'nombres_ayudantes' => $datos['nombres_ayudantes'] ?? null,
                    'comentarios'       => $datos['comentarios'] ?? null,
                    'estado'            => EstadoViaje::EnRuta,
                ]);
            } else {
                $viaje->chofer_id = $choferId;
                $viaje->vehiculo_id = $vehiculoId;
                $viaje->fecha_salida = now();
                $viaje->total_facturado = $camion->monto_total;
                if (array_key_exists('cant_ayudantes', $datos)) {
                    $viaje->cant_ayudantes = (int) $datos['cant_ayudantes'];
                }
                if (array_key_exists('nombres_ayudantes', $datos)) {
                    $viaje->nombres_ayudantes = $datos['nombres_ayudantes'];
                }
                if (array_key_exists('comentarios', $datos)) {
                    $viaje->comentarios = $datos['comentarios'];
                }
                $viaje->save();
            }

            // Sincronizar gastos si se indicaron
            if (!empty($datos['gastos']) && is_array($datos['gastos'])) {
                VehiculoGasto::where('viaje_id', $viaje->id)->delete();
                $totalGastos = 0;
                foreach ($datos['gastos'] as $g) {
                    $monto = (float) ($g['monto_total'] ?? 0);
                    if ($monto <= 0 && !empty($g['cantidad']) && !empty($g['precio_unitario'])) {
                        $monto = (float) $g['cantidad'] * (float) $g['precio_unitario'];
                    }
                    $totalGastos += $monto;

                    VehiculoGasto::create([
                        'viaje_id'        => $viaje->id,
                        'vehiculo_id'     => $vehiculoId,
                        'fecha_gasto'     => now()->toDateString(),
                        'tipo_gasto'      => $g['tipo_gasto'] ?? 'OTRO',
                        'concepto'        => $g['concepto'] ?? ucfirst($g['tipo_gasto'] ?? 'Gasto de viaje'),
                        'cantidad'        => (float) ($g['cantidad'] ?? 1),
                        'unidad_medida'   => 'UNIDAD',
                        'precio_unitario' => (float) ($g['precio_unitario'] ?? $monto),
                        'monto_total'     => $monto,
                        'comprobante'     => !empty($g['comprobante']) ? $g['comprobante'] : null,
                        'comprobantes'    => !empty($g['comprobante']) ? [$g['comprobante']] : null,
                        'registrado_por'  => auth()->id() ?? $camion->vendedor_id,
                    ]);
                }
                $viaje->total_gastos = $totalGastos;
                $viaje->save();
            }

            // Sincronizar o copiar los pedidos asignados al viaje histórico
            $pedidos = $camion->pedidos()->get();
            foreach ($pedidos as $p) {
                CamionViajePedido::updateOrCreate(
                    ['viaje_id' => $viaje->id, 'pedido_id' => $p->id],
                    [
                        'orden_viaje'        => $p->pivot->orden_viaje ?? 0,
                        'estado_entrega'     => EstadoEntrega::EnCurso,
                        'fecha_entregado'    => null,
                        'comentario_entrega' => $p->pivot->comentario_entrega ?? null,
                        'total_pedido'       => $p->total,
                    ]
                );
            }
        });

        return $this->cargarRelaciones($camion->fresh());
    }

    /**
     * Guarda o actualiza los datos preliminares del viaje (gastos, ayudantes, comentarios)
     * SIN cerrar el viaje ni liberar el camión. El viaje continúa en ruta.
     */
    public function guardarDatosViaje(CamionVictual $camion, array $datos, User $responsable): array
    {
        return DB::transaction(function () use ($camion, $datos, $responsable) {
            // Actualizar vehículo y chofer en el camión si se proporcionaron
            $datosCamion = [];
            if (!empty($datos['vehiculo_id'])) {
                $vehiculo = Vehiculo::find($datos['vehiculo_id']);
                if ($vehiculo && $vehiculo->estado !== 'inactivo') {
                    $camion->vehiculo_id = $datos['vehiculo_id'];
                    $datosCamion['vehiculo_id'] = $datos['vehiculo_id'];
                }
            }
            if (!empty($datos['chofer_id'])) {
                $camion->chofer_id = $datos['chofer_id'];
                $datosCamion['chofer_id'] = $datos['chofer_id'];
            }
            if (!empty($datos['dejar_listo']) || $camion->estado === EstadoCamion::Armando) {
                if ($camion->pedidos()->count() > 0) {
                    $camion->estado = EstadoCamion::Listo;
                    $datosCamion['estado'] = EstadoCamion::Listo;
                }
            }
            if (!empty($datosCamion)) {
                $camion->update($datosCamion);
            }

            // Localizar el viaje activo en ruta o crear uno para almacenar estos datos preliminares
            $viaje = CamionViaje::where('camion_victual_id', $camion->id)
                ->where('estado', EstadoViaje::EnRuta)
                ->latest()
                ->first();

            if (!$viaje) {
                $viaje = CamionViaje::create([
                    'codigo'            => CamionViaje::generarSiguienteCodigo(),
                    'camion_victual_id' => $camion->id,
                    'chofer_id'         => $camion->chofer_id,
                    'vehiculo_id'       => $camion->vehiculo_id,
                    'vendedor_id'       => $camion->vendedor_id,
                    'fecha_salida'      => $camion->updated_at ?? now(),
                    'total_facturado'   => $camion->monto_total,
                    'total_gastos'      => 0,
                    'cant_ayudantes'    => 0,
                    'estado'            => EstadoViaje::EnRuta,
                ]);
            } else {
                if (!empty($datos['vehiculo_id'])) {
                    $viaje->vehiculo_id = $datos['vehiculo_id'];
                }
                if (!empty($datos['chofer_id'])) {
                    $viaje->chofer_id = $datos['chofer_id'];
                }
                $viaje->total_facturado = $camion->monto_total;
            }

            // Sincronizar gastos si se envían
            if (array_key_exists('gastos', $datos) && is_array($datos['gastos'])) {
                VehiculoGasto::where('viaje_id', $viaje->id)->delete();

                $totalGastos = 0;
                foreach ($datos['gastos'] as $g) {
                    $monto = (float) ($g['monto_total'] ?? 0);
                    if ($monto <= 0 && !empty($g['cantidad']) && !empty($g['precio_unitario'])) {
                        $monto = (float) $g['cantidad'] * (float) $g['precio_unitario'];
                    }
                    $totalGastos += $monto;

                    VehiculoGasto::create([
                        'viaje_id'        => $viaje->id,
                        'vehiculo_id'     => $viaje->vehiculo_id,
                        'fecha_gasto'     => now()->toDateString(),
                        'tipo_gasto'      => $g['tipo_gasto'] ?? 'OTRO',
                        'concepto'        => $g['concepto'] ?? ucfirst($g['tipo_gasto'] ?? 'Gasto de viaje'),
                        'cantidad'        => (float) ($g['cantidad'] ?? 1),
                        'unidad_medida'   => 'UNIDAD',
                        'precio_unitario' => (float) ($g['precio_unitario'] ?? $monto),
                        'monto_total'     => $monto,
                        'comprobante'     => !empty($g['comprobante']) ? $g['comprobante'] : null,
                        'comprobantes'    => !empty($g['comprobante']) ? [$g['comprobante']] : null,
                        'registrado_por'  => $responsable->id,
                    ]);
                }
                $viaje->total_gastos = $totalGastos;
            }

            if (array_key_exists('cant_ayudantes', $datos)) {
                $viaje->cant_ayudantes = (int) $datos['cant_ayudantes'];
            }
            if (array_key_exists('nombres_ayudantes', $datos)) {
                $viaje->nombres_ayudantes = $datos['nombres_ayudantes'];
            }
            if (array_key_exists('comentarios', $datos)) {
                $viaje->comentarios = $datos['comentarios'];
            }

            $viaje->save();

            // Sincronizar pedidos en el viaje
            $pedidos = $camion->pedidos()->get();
            foreach ($pedidos as $p) {
                CamionViajePedido::firstOrCreate(
                    ['viaje_id' => $viaje->id, 'pedido_id' => $p->id],
                    [
                        'orden_viaje'        => $p->pivot->orden_viaje ?? 0,
                        'estado_entrega'     => $p->pivot->estado_entrega ?? EstadoEntrega::Pendiente->value,
                        'total_pedido'       => $p->total,
                    ]
                );
            }

            return [
                'camion' => $this->cargarRelaciones($camion->fresh()),
                'viaje'  => $viaje->fresh(['gastos', 'pedidos.pedido.cliente', 'chofer.user', 'vendedor']),
            ];
        });
    }

    /**
     * Cerrar el camión manualmente con o sin datos de liquidación.
     */
    public function cerrar(CamionVictual $camion, User $responsable): CamionVictual
    {
        if ($camion->estado !== EstadoCamion::EnRuta) {
            throw new \Exception("Solo se pueden liquidar camiones que se encuentren en ruta. Estado actual: '{$camion->estado->value}'.");
        }
        $res = $this->cerrarConLiquidacion($camion, [], $responsable);
        return $res['camion'];
    }

    /**
     * Cierra el viaje liquidando gastos (combustible, dieta, etc.), ayudantes y comentarios.
     * Guarda el historial de forma permanente y LIBERA el camión dejándolo en VACÍO ($0.00).
     */
    public function cerrarConLiquidacion(CamionVictual $camion, array $datos, User $responsable): array
    {
        if ($camion->estado !== EstadoCamion::EnRuta) {
            throw new \Exception("Solo se pueden liquidar camiones que se encuentren en ruta. Estado actual: '{$camion->estado->value}'.");
        }
        return DB::transaction(function () use ($camion, $datos, $responsable) {
            // 1. Localizar el viaje activo en ruta o crear uno para archivar
            $viaje = CamionViaje::where('camion_victual_id', $camion->id)
                ->where('estado', EstadoViaje::EnRuta)
                ->latest()
                ->first();

            if (!$viaje) {
                $viaje = CamionViaje::create([
                    'codigo'            => CamionViaje::generarSiguienteCodigo(),
                    'camion_victual_id' => $camion->id,
                    'chofer_id'         => $camion->chofer_id,
                    'vehiculo_id'       => $camion->vehiculo_id,
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
            if (array_key_exists('gastos', $datos) && is_array($datos['gastos'])) {
                VehiculoGasto::where('viaje_id', $viaje->id)->delete();
                foreach ($datos['gastos'] as $g) {
                    $monto = (float) ($g['monto_total'] ?? 0);
                    if ($monto <= 0 && !empty($g['cantidad']) && !empty($g['precio_unitario'])) {
                        $monto = (float) $g['cantidad'] * (float) $g['precio_unitario'];
                    }
                    $totalGastos += $monto;

                    VehiculoGasto::create([
                        'viaje_id'        => $viaje->id,
                        'vehiculo_id'     => $viaje->vehiculo_id,
                        'fecha_gasto'     => now()->toDateString(),
                        'tipo_gasto'      => $g['tipo_gasto'] ?? 'OTRO',
                        'concepto'        => $g['concepto'] ?? ucfirst($g['tipo_gasto'] ?? 'Gasto de viaje'),
                        'cantidad'        => (float) ($g['cantidad'] ?? 1),
                        'unidad_medida'   => 'UNIDAD',
                        'precio_unitario' => (float) ($g['precio_unitario'] ?? $monto),
                        'monto_total'     => $monto,
                        'comprobante'     => !empty($g['comprobante']) ? $g['comprobante'] : null,
                        'comprobantes'    => !empty($g['comprobante']) ? [$g['comprobante']] : null,
                        'registrado_por'  => $responsable->id,
                    ]);
                }
            }

            // 3. Sincronizar estados finales de los pedidos en el viaje y actualizar tabla pedidos
            $pedidosCamion = DB::table('camion_victual_pedido')
                ->where('camion_victual_id', $camion->id)
                ->get();

            // Si no se especifica explícitamente en el payload, por defecto en liquidación final
            // los pedidos en ruta pasan a entregados. Solo los pedidos explícitamente 'fallidos'
            // (o si se envía false) se liberan como 'facturado'.
            $marcarRestantesEntregados = array_key_exists('marcar_restantes_entregados', $datos)
                ? (bool) $datos['marcar_restantes_entregados']
                : true;

            foreach ($pedidosCamion as $pc) {
                $estadoEntrega = $pc->estado_entrega;
                $fechaEntregado = $pc->fecha_entregado;

                // Si se solicitó auto-marcar los que siguen en curso o pendiente como entregados:
                if ($marcarRestantesEntregados && ($estadoEntrega === EstadoEntrega::EnCurso->value || $estadoEntrega === EstadoEntrega::Pendiente->value)) {
                    $estadoEntrega = EstadoEntrega::Entregado->value;
                    $fechaEntregado = now();
                }

                // Guardar en el histórico del viaje
                CamionViajePedido::updateOrCreate(
                    ['viaje_id' => $viaje->id, 'pedido_id' => $pc->pedido_id],
                    [
                        'orden_viaje'        => $pc->orden_viaje,
                        'estado_entrega'     => $estadoEntrega,
                        'fecha_entregado'    => $fechaEntregado,
                        'comentario_entrega' => $pc->comentario_entrega,
                    ]
                );

                // Actualizar la tabla general de pedidos:
                if ($estadoEntrega === EstadoEntrega::Entregado->value) {
                    // Pedido ENTREGADO: se finaliza en entregado
                    DB::table('pedidos')
                        ->where('id', $pc->pedido_id)
                        ->update([
                            'estado'     => 'entregado',
                            'updated_at' => now(),
                        ]);
                } else {
                    // Pedido FALLIDO o no entregado: Se LIBERA dejándolo en estado 'facturado'
                    // para que quede disponible para asignarse a otro camión en una nueva ocasión
                    DB::table('pedidos')
                        ->where('id', $pc->pedido_id)
                        ->update([
                            'estado'     => 'facturado',
                            'updated_at' => now(),
                        ]);
                }
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

            // 5. LIBERAR EL CAMIÓN: desvincular pedidos, volverlo a estado VACÍO ($0.00),
            // restaurar el chofer virtual por defecto y liberar el vehículo físico asignado.
            $choferVictualId = $this->getChoferVictualId();
            $camion->pedidos()->detach();
            $camion->update([
                'estado'       => EstadoCamion::Vacio,
                'monto_total'  => 0.00,
                'fecha_cierre' => now(),
                'cerrado_por'  => $responsable->id,
                'chofer_id'    => $choferVictualId,
                'vehiculo_id'  => null,
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
            'vehiculo',
            'cerradoPor:id,name',
            'gastos',
            'pedidos.pedido.cliente:id,nombre',
        ])->orderBy('id', 'desc');

        if (!empty($filtros['chofer_id'])) {
            $query->where('chofer_id', $filtros['chofer_id']);
        }

        if (!empty($filtros['vehiculo_id'])) {
            $query->where('vehiculo_id', $filtros['vehiculo_id']);
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
            'vehiculo',
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
                'estado'      => EstadoCamion::Vacio,
                'monto_total' => 0.00,
                'chofer_id'   => $this->getChoferVictualId(),
                'vehiculo_id' => null,
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
            'vehiculo',
            'viajeActivo.gastos',
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
