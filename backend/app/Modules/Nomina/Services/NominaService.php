<?php

namespace App\Modules\Nomina\Services;

use App\Models\User;
use App\Modules\Empleado\Models\Empleado;
use App\Modules\Empleado\Services\EmpleadoService;
use App\Modules\Nomina\Enums\EstadoNomina;
use App\Modules\Nomina\Enums\TipoPeriodoNomina;
use App\Modules\Nomina\Models\Nomina;
use App\Modules\Nomina\Models\NominaConcepto;
use App\Modules\Nomina\Models\NominaDetalle;
use App\Modules\Nomina\Models\NominaDetalleConcepto;
use App\Modules\Nomina\Models\NominaEmpleadoRecurrente;
use App\Modules\Nomina\Models\NominaEscalaIsr;
use Illuminate\Support\Facades\DB;

class NominaService
{
    public function __construct(
        private readonly EmpleadoService $empleadoService
    ) {}

    /**
     * Crear un nuevo periodo de nómina en borrador.
     */
    public function crearPeriodo(array $datos, ?User $creador = null): Nomina
    {
        return DB::transaction(function () use ($datos, $creador) {
            if (empty($datos['codigo'])) {
                $periodo = $datos['tipo_periodo'] ?? 'quincenal';
                $fecha = $datos['fecha_pago'] ?? now()->toDateString();
                $datos['codigo'] = 'NOM-' . date('Y-m', strtotime($fecha)) . '-' . strtoupper(substr($periodo, 0, 1)) . rand(10, 99);
            }

            if ($creador) {
                $datos['realizado_por'] = $creador->id;
            }

            $datos['estado'] = EstadoNomina::Borrador->value;

            return Nomina::create($datos);
        });
    }

    /**
     * Calcular y procesar automáticamente la nómina para todos los empleados activos.
     */
    public function calcularNomina(Nomina $nomina): Nomina
    {
        return DB::transaction(function () use ($nomina) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if ($nomina->estado === EstadoNomina::Aprobada || $nomina->estado === EstadoNomina::Pagada) {
                throw new \DomainException('No se puede recalcular una nómina que ya fue aprobada o pagada.');
            }

            if ($nomina->estado === EstadoNomina::Anulada) {
                throw new \DomainException('No se puede calcular una nómina que está anulada.');
            }

            $empleados = $this->empleadoService->getActivosParaNomina();
            if ($empleados->isEmpty()) {
                throw new \DomainException('No hay colaboradores activos en el sistema para procesar en este periodo.');
            }

            // Eliminar detalles previos si ya se había calculado
            $nomina->detalles()->delete();

            $conceptos = NominaConcepto::where('activo', true)->get()->keyBy('codigo');

            $totalNominaIngresos = 0;
            $totalNominaDeducciones = 0;

            $esQuincenal = $nomina->tipo_periodo === TipoPeriodoNomina::Quincenal;

            foreach ($empleados as $empleado) {
                $salarioPeriodo = $esQuincenal ? (float)$empleado->salario_quincenal : (float)$empleado->salario_mensual;

                $detalle = NominaDetalle::create([
                    'nomina_id'          => $nomina->id,
                    'empleado_id'        => $empleado->id,
                    'salario_mensual'    => $empleado->salario_mensual,
                    'salario_periodo'    => $salarioPeriodo,
                    'salario_hora'       => $empleado->salario_hora,
                    'dias_trabajados'    => $esQuincenal ? 15 : 30,
                    'horas_trabajadas'   => $esQuincenal ? 120 : 240,
                    'horas_no_laboradas' => 0,
                    'horas_extras'       => 0,
                    'total_ingresos'     => 0,
                    'total_deducciones'  => 0,
                    'neto_pagar'         => 0,
                ]);

                $empIngresos = 0;
                $empDeducciones = 0;

                // 1. Ingreso Base: Salario Ordinario
                if (isset($conceptos['SALARIO_ORDINARIO']) && $salarioPeriodo > 0) {
                    $c = $conceptos['SALARIO_ORDINARIO'];
                    NominaDetalleConcepto::create([
                        'nomina_detalle_id' => $detalle->id,
                        'concepto_id'       => $c->id,
                        'tipo'              => 'ingreso',
                        'monto'             => $salarioPeriodo,
                        'cantidad'          => $esQuincenal ? 15 : 30,
                        'notas'             => 'Salario base ordinario del periodo',
                    ]);
                    $empIngresos += $salarioPeriodo;
                }

                // 2. Deducciones recurrentes (préstamos, ahorros, cuotas activas)
                $recurrentes = NominaEmpleadoRecurrente::where('empleado_id', $empleado->id)
                    ->where('activo', true)
                    ->with('concepto')
                    ->get();

                foreach ($recurrentes as $rec) {
                    $montoCuota = (float) $rec->monto_cuota;
                    if ($rec->saldo_restante > 0 && $montoCuota > $rec->saldo_restante) {
                        $montoCuota = (float) $rec->saldo_restante;
                    }

                    if ($montoCuota > 0) {
                        $cuotaTxt = ($rec->cuotas_pagadas + 1) . '/' . $rec->cuotas_totales;
                        NominaDetalleConcepto::create([
                            'nomina_detalle_id' => $detalle->id,
                            'concepto_id'       => $rec->concepto_id,
                            'tipo'              => 'deduccion',
                            'monto'             => $montoCuota,
                            'referencia_cuota'  => $cuotaTxt,
                            'notas'             => $rec->descripcion,
                        ]);
                        $empDeducciones += $montoCuota;
                    }
                }

                // 3. Ley de Seguridad Social Dominicana (TSS - Ley 87-01)
                $baseCotizable = $salarioPeriodo;
                $anioNomina = $nomina->fecha_pago ? (int) date('Y', strtotime($nomina->fecha_pago)) : (int) date('Y');

                $tasaAfp = isset($conceptos['AFP_EMP']) && (float)$conceptos['AFP_EMP']->porcentaje > 0
                    ? ((float)$conceptos['AFP_EMP']->porcentaje / 100.0)
                    : 0.0287;
                $tasaArs = isset($conceptos['ARS_EMP']) && (float)$conceptos['ARS_EMP']->porcentaje > 0
                    ? ((float)$conceptos['ARS_EMP']->porcentaje / 100.0)
                    : 0.0304;

                // AFP
                if ($empleado->aplica_afp && isset($conceptos['AFP_EMP'])) {
                    $c = $conceptos['AFP_EMP'];
                    $afpMonto = round($baseCotizable * $tasaAfp, 2);
                    if ($afpMonto > 0) {
                        NominaDetalleConcepto::create([
                            'nomina_detalle_id' => $detalle->id,
                            'concepto_id'       => $c->id,
                            'tipo'              => 'deduccion',
                            'monto'             => $afpMonto,
                            'notas'             => null,
                        ]);
                        $empDeducciones += $afpMonto;
                    }
                }

                // ARS / SFS
                if ($empleado->aplica_ars && isset($conceptos['ARS_EMP'])) {
                    $c = $conceptos['ARS_EMP'];
                    $arsMonto = round($baseCotizable * $tasaArs, 2);
                    if ($arsMonto > 0) {
                        NominaDetalleConcepto::create([
                            'nomina_detalle_id' => $detalle->id,
                            'concepto_id'       => $c->id,
                            'tipo'              => 'deduccion',
                            'monto'             => $arsMonto,
                            'notas'             => null,
                        ]);
                        $empDeducciones += $arsMonto;
                    }
                }

                // 4. Retención ISR Asalariados (DGII República Dominicana Dinámica)
                if ($empleado->aplica_isr && isset($conceptos['RET_ISR'])) {
                    $isrMonto = $this->calcularIsrPeriodo(
                        (float)$empleado->salario_mensual,
                        $esQuincenal,
                        (bool)$empleado->aplica_afp,
                        (bool)$empleado->aplica_ars,
                        $anioNomina,
                        $tasaAfp,
                        $tasaArs
                    );
                    if ($isrMonto > 0) {
                        $c = $conceptos['RET_ISR'];
                        NominaDetalleConcepto::create([
                            'nomina_detalle_id' => $detalle->id,
                            'concepto_id'       => $c->id,
                            'tipo'              => 'deduccion',
                            'monto'             => $isrMonto,
                            'notas'             => null,
                        ]);
                        $empDeducciones += $isrMonto;
                    }
                }

                // Actualizar detalle del empleado
                $netoPagar = round($empIngresos - $empDeducciones, 2);
                $detalle->update([
                    'total_ingresos'    => $empIngresos,
                    'total_deducciones' => $empDeducciones,
                    'neto_pagar'        => $netoPagar,
                ]);

                $totalNominaIngresos += $empIngresos;
                $totalNominaDeducciones += $empDeducciones;
            }

            $totalNeto = round($totalNominaIngresos - $totalNominaDeducciones, 2);

            $nomina->update([
                'total_ingresos'    => $totalNominaIngresos,
                'total_deducciones' => $totalNominaDeducciones,
                'total_neto'        => $totalNeto,
                'estado'            => EstadoNomina::Calculada->value,
            ]);

            return $nomina->fresh(['detalles.empleado', 'detalles.conceptos.concepto']);
        });
    }

    /**
     * Agregar una novedad o concepto manual (horas extras, feriados, comisiones, bonos) a un colaborador.
     */
    public function agregarConceptoDetalle(Nomina $nomina, NominaDetalle $detalle, array $datos): Nomina
    {
        return DB::transaction(function () use ($nomina, $detalle, $datos) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if (!in_array($nomina->estado, [EstadoNomina::Borrador, EstadoNomina::Calculada])) {
                throw new \DomainException('Solo se pueden agregar novedades a nóminas en borrador o calculadas.');
            }

            $concepto = NominaConcepto::findOrFail($datos['concepto_id']);
            $monto = round((float)$datos['monto'], 2);
            if ($monto <= 0) {
                throw new \DomainException('El monto debe ser superior a cero.');
            }

            NominaDetalleConcepto::create([
                'nomina_detalle_id' => $detalle->id,
                'concepto_id'       => $concepto->id,
                'tipo'              => $concepto->tipo->value ?? ($concepto->tipo == 'ingreso' ? 'ingreso' : 'deduccion'),
                'monto'             => $monto,
                'cantidad'          => isset($datos['cantidad']) && (float)$datos['cantidad'] > 0 ? (float)$datos['cantidad'] : null,
                'valor_unitario'    => isset($datos['valor_unitario']) ? (float)$datos['valor_unitario'] : null,
                'notas'             => $datos['notas'] ?? null,
            ]);

            if (str_contains($concepto->codigo, 'HORAS_EXTRAS') && isset($datos['cantidad'])) {
                $detalle->increment('horas_extras', (float)$datos['cantidad']);
            }

            $this->recalcularTotalesNomina($nomina);

            return $nomina->fresh(['detalles.empleado', 'detalles.conceptos.concepto']);
        });
    }

    /**
     * Eliminar un concepto o novedad de un colaborador.
     */
    public function eliminarConceptoDetalle(Nomina $nomina, NominaDetalle $detalle, NominaDetalleConcepto $conceptoDetalle): Nomina
    {
        return DB::transaction(function () use ($nomina, $detalle, $conceptoDetalle) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if (!in_array($nomina->estado, [EstadoNomina::Borrador, EstadoNomina::Calculada])) {
                throw new \DomainException('Solo se pueden modificar novedades en nóminas en borrador o calculadas.');
            }

            $concepto = NominaConcepto::find($conceptoDetalle->concepto_id);
            if ($concepto && $concepto->codigo === 'SALARIO_ORDINARIO') {
                throw new \DomainException('No se puede eliminar el salario ordinario base.');
            }

            if ($concepto && str_contains($concepto->codigo, 'HORAS_EXTRAS') && $conceptoDetalle->cantidad) {
                $horasRestar = (float)$conceptoDetalle->cantidad;
                $nuevoTotalHoras = max(0, (float)$detalle->horas_extras - $horasRestar);
                $detalle->update(['horas_extras' => $nuevoTotalHoras]);
            }

            $conceptoDetalle->delete();

            $this->recalcularTotalesNomina($nomina);

            return $nomina->fresh(['detalles.empleado', 'detalles.conceptos.concepto']);
        });
    }

    /**
     * Recalcula los totales de cada detalle y de la nómina global.
     */
    public function recalcularTotalesNomina(Nomina $nomina): void
    {
        $detalles = NominaDetalle::where('nomina_id', $nomina->id)->with('conceptos')->get();
        $totalNominaIngresos = 0;
        $totalNominaDeducciones = 0;

        foreach ($detalles as $det) {
            $empIngresos = (float) $det->conceptos->filter(fn($c) => ($c->tipo->value ?? $c->tipo) === 'ingreso')->sum('monto');
            $empDeducciones = (float) $det->conceptos->filter(fn($c) => ($c->tipo->value ?? $c->tipo) === 'deduccion')->sum('monto');
            $netoPagar = round($empIngresos - $empDeducciones, 2);

            $det->update([
                'total_ingresos'    => $empIngresos,
                'total_deducciones' => $empDeducciones,
                'neto_pagar'        => $netoPagar,
            ]);

            $totalNominaIngresos += $empIngresos;
            $totalNominaDeducciones += $empDeducciones;
        }

        $totalNeto = round($totalNominaIngresos - $totalNominaDeducciones, 2);

        $nomina->update([
            'total_ingresos'    => $totalNominaIngresos,
            'total_deducciones' => $totalNominaDeducciones,
            'total_neto'        => $totalNeto,
        ]);
    }

    /**
     * Aprobar la nómina y aplicar el avance de cuotas a los préstamos/ahorros recurrentes.
     */
    public function aprobarNomina(Nomina $nomina, User $usuario): Nomina
    {
        return DB::transaction(function () use ($nomina, $usuario) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if ($nomina->estado !== EstadoNomina::Calculada) {
                throw new \DomainException('Solo se pueden aprobar nóminas en estado calculada. Por favor calcule la nómina primero.');
            }

            if ($nomina->detalles()->count() === 0) {
                throw new \DomainException('La nómina no contiene colaboradores procesados.');
            }

            // Avanzar cuotas en préstamos recurrentes
            foreach ($nomina->detalles()->with('conceptos')->get() as $detalle) {
                foreach ($detalle->conceptos as $linea) {
                    if ($linea->referencia_cuota) {
                        $rec = NominaEmpleadoRecurrente::where('empleado_id', $detalle->empleado_id)
                            ->where('concepto_id', $linea->concepto_id)
                            ->where('activo', true)
                            ->lockForUpdate()
                            ->first();

                        if ($rec) {
                            $nuevasPagadas = $rec->cuotas_pagadas + 1;
                            $nuevoSaldo = max(0, $rec->saldo_restante - $linea->monto);
                            $activo = ($nuevasPagadas < $rec->cuotas_totales) && ($nuevoSaldo > 0);

                            $rec->update([
                                'cuotas_pagadas' => $nuevasPagadas,
                                'saldo_restante' => $nuevoSaldo,
                                'activo'         => $activo,
                            ]);
                        }
                    }
                }
            }

            $nomina->update([
                'estado'       => EstadoNomina::Aprobada->value,
                'aprobado_por' => $usuario->id,
            ]);

            return $nomina->fresh(['detalles.empleado', 'detalles.conceptos.concepto']);
        });
    }

    /**
     * Marcar nómina como pagada.
     */
    public function pagarNomina(Nomina $nomina, User $usuario): Nomina
    {
        return DB::transaction(function () use ($nomina, $usuario) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if ($nomina->estado !== EstadoNomina::Aprobada) {
                throw new \DomainException('Solo se pueden pagar nóminas previamente aprobadas.');
            }

            $nomina->update([
                'estado' => EstadoNomina::Pagada->value,
            ]);

            return $nomina->fresh(['detalles.empleado', 'detalles.conceptos.concepto']);
        });
    }

    /**
     * Anular una nómina. Si estaba aprobada, revierte atómicamente el avance de cuotas de préstamos.
     */
    public function anularNomina(Nomina $nomina, User $usuario, ?string $motivo = null): Nomina
    {
        return DB::transaction(function () use ($nomina, $usuario, $motivo) {
            $nomina = Nomina::where('id', $nomina->id)->lockForUpdate()->firstOrFail();

            if ($nomina->estado === EstadoNomina::Pagada) {
                throw new \DomainException('No se puede anular una nómina que ya fue pagada. Debe registrarse un ajuste.');
            }

            if ($nomina->estado === EstadoNomina::Anulada) {
                throw new \DomainException('La nómina ya se encuentra anulada.');
            }

            // Si estaba aprobada, revertir cuotas de préstamos
            if ($nomina->estado === EstadoNomina::Aprobada) {
                foreach ($nomina->detalles()->with('conceptos')->get() as $detalle) {
                    foreach ($detalle->conceptos as $linea) {
                        if ($linea->referencia_cuota) {
                            $rec = NominaEmpleadoRecurrente::where('empleado_id', $detalle->empleado_id)
                                ->where('concepto_id', $linea->concepto_id)
                                ->lockForUpdate()
                                ->first();

                            if ($rec) {
                                $cuotasPrevias = max(0, $rec->cuotas_pagadas - 1);
                                $saldoPrevio = $rec->saldo_restante + $linea->monto;

                                $rec->update([
                                    'cuotas_pagadas' => $cuotasPrevias,
                                    'saldo_restante' => $saldoPrevio,
                                    'activo'         => true,
                                ]);
                            }
                        }
                    }
                }
            }

            $nomina->update([
                'estado' => EstadoNomina::Anulada->value,
                'notas'  => trim(($nomina->notas ?? '') . ' [ANULADA por ' . $usuario->name . ': ' . ($motivo ?? 'Sin motivo') . ']'),
            ]);

            return $nomina->fresh();
        });
    }

    /**
     * Resumen general del módulo nómina.
     */
    public function resumen(): array
    {
        $totalNominas = Nomina::count();
        $borradores = Nomina::where('estado', EstadoNomina::Borrador->value)->count();
        $calculadas = Nomina::where('estado', EstadoNomina::Calculada->value)->count();
        $aprobadas = Nomina::where('estado', EstadoNomina::Aprobada->value)->count();
        $pagadas = Nomina::where('estado', EstadoNomina::Pagada->value)->count();

        $montoTotalPagadoAno = (float) Nomina::where('estado', EstadoNomina::Pagada->value)
            ->whereYear('fecha_pago', date('Y'))
            ->sum('total_neto');

        $ultimaNomina = Nomina::latest('fecha_pago')->first();

        return [
            'total_nominas'          => $totalNominas,
            'borradores'             => $borradores,
            'calculadas'             => $calculadas,
            'aprobadas'              => $aprobadas,
            'pagadas'                => $pagadas,
            'total_pagado_anio'      => $montoTotalPagadoAno,
            'ultima_nomina_fecha'    => $ultimaNomina?->fecha_pago?->toDateString(),
            'ultima_nomina_total'    => (float)($ultimaNomina?->total_neto ?? 0),
        ];
    }

    /**
     * Cálculo Dinámico de Retención de ISR para Asalariados según escala oficial DGII República Dominicana.
     * Consulta la base de datos (tabla nomina_escalas_isr) según el año de la nómina.
     * 
     * Si no se configuran tramos para un año específico, toma automáticamente la última escala activa
     * registrada o la escala legal por defecto. ¡Cero necesidad de recompilar la aplicación!
     */
    public function calcularIsrPeriodo(
        float $salarioMensual,
        bool $esQuincenal,
        bool $aplicaAfp = true,
        bool $aplicaArs = true,
        ?int $anio = null,
        ?float $tasaAfp = null,
        ?float $tasaArs = null
    ): float {
        if ($salarioMensual <= 0) return 0.0;

        // Tasas de TSS (Ley 87-01)
        $tAfp = $tasaAfp ?? 0.0287;
        $tArs = $tasaArs ?? 0.0304;

        $tssTasa = 0.0;
        if ($aplicaAfp) $tssTasa += $tAfp;
        if ($aplicaArs) $tssTasa += $tArs;

        $salarioNetoMensual = $salarioMensual * (1 - $tssTasa);
        $impuestoMensual = 0.0;

        // Consultar tramos dinámicos en base de datos
        $anio = $anio ?? (int) date('Y');
        $escalas = NominaEscalaIsr::where('anio', $anio)
            ->where('activo', true)
            ->orderBy('desde_mensual')
            ->get();

        if ($escalas->isEmpty()) {
            $escalas = NominaEscalaIsr::where('activo', true)
                ->orderByDesc('anio')
                ->orderBy('desde_mensual')
                ->get();
        }

        if ($escalas->isNotEmpty()) {
            foreach ($escalas as $tramo) {
                $desde = (float)$tramo->desde_mensual;
                $hasta = $tramo->hasta_mensual !== null ? (float)$tramo->hasta_mensual : INF;

                if ($salarioNetoMensual >= $desde && $salarioNetoMensual <= $hasta) {
                    $excedenteBase = (float)$tramo->excedente_desde_mensual;
                    $excedente = max(0, $salarioNetoMensual - $excedenteBase);
                    $porcentaje = ((float)$tramo->tasa_porcentaje) / 100.0;
                    $impuestoMensual = (float)$tramo->impuesto_base_mensual + ($excedente * $porcentaje);
                    break;
                }
            }
        } else {
            // Fallback de contingencia si la tabla estuviera vacía
            if ($salarioNetoMensual <= 34685.00) {
                $impuestoMensual = 0.0;
            } elseif ($salarioNetoMensual <= 52027.42) {
                $excedente = $salarioNetoMensual - 34685.00;
                $impuestoMensual = $excedente * 0.15;
            } elseif ($salarioNetoMensual <= 72260.25) {
                $excedente = $salarioNetoMensual - 52027.42;
                $impuestoMensual = 2601.33 + ($excedente * 0.20);
            } else {
                $excedente = $salarioNetoMensual - 72260.25;
                $impuestoMensual = 6648.00 + ($excedente * 0.25);
            }
        }

        return $esQuincenal ? round($impuestoMensual / 2, 2) : round($impuestoMensual, 2);
    }

    /**
     * Obtener escalas de retención y parámetros fiscales activos para el frontend.
     */
    public function getEscalasIsr(?int $anio = null): array
    {
        $anio = $anio ?? (int) date('Y');
        $escalas = NominaEscalaIsr::where('anio', $anio)
            ->where('activo', true)
            ->orderBy('desde_mensual')
            ->get();

        if ($escalas->isEmpty()) {
            $escalas = NominaEscalaIsr::where('activo', true)
                ->orderByDesc('anio')
                ->orderBy('desde_mensual')
                ->get();
        }

        $afpConcepto = NominaConcepto::where('codigo', 'AFP_EMP')->first();
        $arsConcepto = NominaConcepto::where('codigo', 'ARS_EMP')->first();

        $tasaAfp = $afpConcepto && $afpConcepto->porcentaje > 0 ? (float)$afpConcepto->porcentaje / 100.0 : 0.0287;
        $tasaArs = $arsConcepto && $arsConcepto->porcentaje > 0 ? (float)$arsConcepto->porcentaje / 100.0 : 0.0304;

        return [
            'anio'      => $anio,
            'escalas'   => $escalas,
            'tasa_afp'  => $tasaAfp,
            'tasa_ars'  => $tasaArs,
            'tasa_tss'  => round($tasaAfp + $tasaArs, 4),
        ];
    }
}

