<?php

namespace App\Modules\Empleado\Services;

use App\Models\User;
use App\Modules\Empleado\Enums\EstadoEmpleado;
use App\Modules\Empleado\Models\Empleado;
use Illuminate\Support\Facades\DB;

class EmpleadoService
{
    /**
     * Crear un nuevo empleado con salarios quincenal y por hora calculados automáticamente.
     */
    public function crear(array $datos, ?User $responsable = null): Empleado
    {
        return DB::transaction(function () use ($datos, $responsable) {
            $datos = $this->calcularSalariosDerivados($datos);

            if (isset($datos['cedula'])) {
                $datos['cedula'] = $this->normalizarCedula($datos['cedula']);
            }

            if ($responsable) {
                $datos['created_by'] = $responsable->id;
            }

            return Empleado::create($datos);
        });
    }

    /**
     * Actualizar datos del empleado.
     */
    public function actualizar(Empleado $empleado, array $datos): Empleado
    {
        return DB::transaction(function () use ($empleado, $datos) {
            if (isset($datos['salario_mensual'])) {
                $datos = $this->calcularSalariosDerivados($datos);
            }

            if (isset($datos['cedula'])) {
                $datos['cedula'] = $this->normalizarCedula($datos['cedula']);
            }

            if (isset($datos['estado'])) {
                $datos['estado'] = EstadoEmpleado::from($datos['estado']);
            }

            $empleado->update($datos);
            return $empleado->fresh();
        });
    }

    /**
     * Regla de negocio: Los colaboradores no se eliminan físicamente ni por soft delete
     * para no romper el historial de nóminas pasadas.
     */
    public function eliminar(Empleado $empleado): void
    {
        throw new \DomainException('Los empleados no pueden ser eliminados para preservar el historial de nómina.');
    }

    /**
     * Resumen estadístico de empleados y masa salarial.
     */
    public function resumen(): array
    {
        $total = Empleado::count();
        $activos = Empleado::where('estado', EstadoEmpleado::Activo->value)->count();
        $inactivos = Empleado::where('estado', EstadoEmpleado::Inactivo->value)->count();
        $vacaciones = Empleado::where('estado', EstadoEmpleado::Vacaciones->value)->count();
        $licencia = Empleado::where('estado', EstadoEmpleado::Licencia->value)->count();

        $masaMensual = (float) Empleado::where('estado', EstadoEmpleado::Activo->value)->sum('salario_mensual');
        $masaQuincenal = round($masaMensual / 2, 2);

        return [
            'total_empleados'         => $total,
            'activos'                 => $activos,
            'inactivos'               => $inactivos,
            'en_vacaciones'           => $vacaciones,
            'en_licencia'             => $licencia,
            'masa_salarial_mensual'   => $masaMensual,
            'masa_salarial_quincenal' => $masaQuincenal,
        ];
    }

    /**
     * Empleados activos listos para ser procesados en una nómina.
     */
    public function getActivosParaNomina()
    {
        return Empleado::where('estado', EstadoEmpleado::Activo->value)
            ->orderBy('nombres')
            ->orderBy('apellidos')
            ->get();
    }

    /**
     * Fórmula legal RD (Código de Trabajo Art. 85 / Res. 51-2017):
     * Salario por hora = Salario Mensual / 23.83 / 8
     * Salario quincenal = Salario Mensual / 2
     */
    public function calcularSalariosDerivados(array $datos): array
    {
        if (isset($datos['salario_mensual'])) {
            $mensual = (float) $datos['salario_mensual'];
            $datos['salario_quincenal'] = round($mensual / 2, 2);
            $datos['salario_hora'] = $mensual > 0 ? round($mensual / 23.83 / 8, 4) : 0;
        }

        return $datos;
    }

    /**
     * Normalizar cédula al formato dominicano XXX-XXXXXXX-X si contiene 11 dígitos.
     */
    public function normalizarCedula(?string $raw): ?string
    {
        if (!$raw) {
            return null;
        }
        $digits = preg_replace('/\D/', '', $raw);
        if (strlen($digits) === 11) {
            return substr($digits, 0, 3) . '-' . substr($digits, 3, 7) . '-' . substr($digits, 10, 1);
        }
        return $raw;
    }
}

