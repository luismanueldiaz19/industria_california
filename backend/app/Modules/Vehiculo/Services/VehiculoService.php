<?php

namespace App\Modules\Vehiculo\Services;

use App\Models\User;
use App\Modules\Vehiculo\Enums\EstadoMantenimiento;
use App\Modules\Vehiculo\Enums\EstadoVehiculo;
use App\Modules\Vehiculo\Enums\TipoMantenimiento;
use App\Modules\Vehiculo\Models\Vehiculo;
use App\Modules\Vehiculo\Models\VehiculoGasto;
use App\Modules\Vehiculo\Models\VehiculoMantenimiento;
use Illuminate\Support\Facades\DB;

class VehiculoService
{
    // ─── Vehículo ─────────────────────────────────────────────────

    /**
     * Crear un nuevo vehículo en la flota.
     */
    public function crear(array $datos, User $responsable): Vehiculo
    {
        $datos['created_by'] = $responsable->id;

        return Vehiculo::create($datos);
    }

    /**
     * Actualizar los datos de un vehículo.
     *
     * @throws \Exception si el vehículo tiene mantenimientos activos y se intenta pasar a disponible directamente
     */
    public function actualizar(Vehiculo $vehiculo, array $datos): Vehiculo
    {
        // Validar transición de estado
        if (isset($datos['estado'])) {
            $nuevoEstado = EstadoVehiculo::from($datos['estado']);

            if ($nuevoEstado === EstadoVehiculo::Disponible && $vehiculo->estado === EstadoVehiculo::EnMantenimiento) {
                $mantenimientosActivos = $vehiculo->mantenimientos()
                    ->whereIn('estado', [
                        EstadoMantenimiento::Pendiente->value,
                        EstadoMantenimiento::EnProceso->value,
                    ])->count();

                if ($mantenimientosActivos > 0) {
                    throw new \Exception(
                        "No se puede marcar como disponible. El vehículo tiene {$mantenimientosActivos} mantenimiento(s) activo(s) pendiente(s) de resolver."
                    );
                }
            }

            $datos['estado'] = $nuevoEstado;
        }

        $vehiculo->update($datos);
        return $vehiculo->fresh();
    }

    /**
     * Eliminar un vehículo.
     *
     * @throws \Exception si tiene historial de gastos o mantenimientos
     */
    public function eliminar(Vehiculo $vehiculo): void
    {
        if ($vehiculo->mantenimientos()->count() > 0 || $vehiculo->gastos()->count() > 0) {
            throw new \Exception(
                'No se puede eliminar el vehículo porque tiene historial de mantenimientos o gastos registrados.'
            );
        }

        $vehiculo->delete();
    }

    // ─── Mantenimientos ───────────────────────────────────────────

    /**
     * Registrar un nuevo mantenimiento para un vehículo.
     * Cambia automáticamente el estado del vehículo a "en_mantenimiento" si el tipo es avería.
     */
    public function registrarMantenimiento(Vehiculo $vehiculo, array $datos, User $responsable): VehiculoMantenimiento
    {
        return DB::transaction(function () use ($vehiculo, $datos, $responsable) {
            $mantenimiento = $vehiculo->mantenimientos()->create([
                'tipo'          => $datos['tipo'],
                'fecha_reporte' => $datos['fecha_reporte'] ?? now(),
                'descripcion'   => $datos['descripcion'],
                'costo'         => $datos['costo'] ?? 0,
                'estado'        => EstadoMantenimiento::Pendiente,
                'evidencias'    => $datos['evidencias'] ?? null,
                'reportado_por' => $responsable->id,
            ]);

            // Si es avería, el vehículo pasa a en_mantenimiento automáticamente
            if (TipoMantenimiento::from($datos['tipo']) === TipoMantenimiento::Averia) {
                $vehiculo->update(['estado' => EstadoVehiculo::EnMantenimiento]);
            }

            return $mantenimiento->load('reportador:id,name');
        });
    }

    /**
     * Actualizar un mantenimiento existente.
     * Si se resuelve y no quedan más activos, devuelve el vehículo a "disponible".
     */
    public function actualizarMantenimiento(
        Vehiculo $vehiculo,
        VehiculoMantenimiento $mantenimiento,
        array $datos
    ): VehiculoMantenimiento {
        return DB::transaction(function () use ($vehiculo, $mantenimiento, $datos) {
            $mantenimiento->update($datos);

            // Si se resuelve, verificar si el vehículo puede volver a disponible
            if (
                isset($datos['estado']) &&
                EstadoMantenimiento::from($datos['estado']) === EstadoMantenimiento::Resuelto &&
                $vehiculo->estado === EstadoVehiculo::EnMantenimiento
            ) {
                $activos = $vehiculo->mantenimientos()
                    ->whereIn('estado', [
                        EstadoMantenimiento::Pendiente->value,
                        EstadoMantenimiento::EnProceso->value,
                    ])->count();

                if ($activos === 0) {
                    $vehiculo->update(['estado' => EstadoVehiculo::Disponible]);
                }
            }

            return $mantenimiento->fresh()->load('reportador:id,name');
        });
    }

    /**
     * Eliminar un mantenimiento.
     *
     * @throws \Exception si ya fue resuelto
     */
    public function eliminarMantenimiento(VehiculoMantenimiento $mantenimiento): void
    {
        if ($mantenimiento->estado === EstadoMantenimiento::Resuelto) {
            throw new \Exception('No se puede eliminar un mantenimiento ya resuelto.');
        }

        $mantenimiento->delete();
    }

    // ─── Gastos ───────────────────────────────────────────────────

    /**
     * Registrar un nuevo gasto para un vehículo.
     * Calcula automáticamente el monto_total si no se provee.
     */
    public function registrarGasto(Vehiculo $vehiculo, array $datos, User $responsable): VehiculoGasto
    {
        $cantidad       = (float) ($datos['cantidad'] ?? 1);
        $precioUnitario = (float) ($datos['precio_unitario'] ?? 0);
        $montoTotal     = $datos['monto_total'] ?? ($cantidad * $precioUnitario);

        return $vehiculo->gastos()->create([
            'fecha_gasto'     => $datos['fecha_gasto'] ?? today(),
            'tipo_gasto'      => $datos['tipo_gasto'] ?? null,
            'concepto'        => $datos['concepto'],
            'cantidad'        => $cantidad,
            'unidad_medida'   => $datos['unidad_medida'] ?? null,
            'precio_unitario' => $precioUnitario,
            'monto_total'     => $montoTotal,
            'comprobantes'    => $datos['comprobantes'] ?? null,
            'registrado_por'  => $responsable->id,
        ]);
    }

    /**
     * Actualizar un gasto registrado.
     */
    public function actualizarGasto(VehiculoGasto $gasto, array $datos): VehiculoGasto
    {
        // Recalcular monto_total si cambia cantidad o precio_unitario
        if (isset($datos['cantidad']) || isset($datos['precio_unitario'])) {
            $cantidad       = (float) ($datos['cantidad'] ?? $gasto->cantidad);
            $precioUnitario = (float) ($datos['precio_unitario'] ?? $gasto->precio_unitario);
            $datos['monto_total'] = $datos['monto_total'] ?? ($cantidad * $precioUnitario);
        }

        $gasto->update($datos);
        return $gasto->fresh();
    }

    /**
     * Eliminar un gasto.
     */
    public function eliminarGasto(VehiculoGasto $gasto): void
    {
        $gasto->delete();
    }

    // ─── Resumen / Estadísticas ───────────────────────────────────

    /**
     * Resumen general de la flota (conteos por estado).
     */
    public function resumenFlota(): array
    {
        $total = Vehiculo::count();

        $porEstado = Vehiculo::selectRaw('estado, count(*) as total')
            ->groupBy('estado')
            ->pluck('total', 'estado')
            ->toArray();

        return [
            'total'            => $total,
            'disponibles'      => $porEstado[EstadoVehiculo::Disponible->value] ?? 0,
            'en_mantenimiento' => $porEstado[EstadoVehiculo::EnMantenimiento->value] ?? 0,
            'inactivos'        => $porEstado[EstadoVehiculo::Inactivo->value] ?? 0,
        ];
    }
}
