<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. CATÁLOGO DE CONCEPTOS (INGRESOS Y DEDUCCIONES ESCALABLES)
        Schema::create('nomina_conceptos', function (Blueprint $table) {
            $table->id();
            $table->string('codigo', 50)->unique(); // SALARIO_QUINCENAL, AFP_EMP, ARS_EMP, RET_ISR, etc.
            $table->string('nombre', 120);
            $table->enum('tipo', ['ingreso', 'deduccion']);
            $table->string('categoria', 40)->default('general'); // salario, ley, prestamo, ahorro, novedad, adelanto, seguro
            $table->boolean('es_automatico')->default(false); // calculo por sistema
            $table->boolean('es_porcentual')->default(false);
            $table->decimal('porcentaje', 6, 4)->nullable(); // ej: 2.8700, 3.0400
            $table->boolean('es_cotizable_tss')->default(false);
            $table->boolean('es_gravable_isr')->default(false);
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });

        // 2. CABECERA DEL PERIODO DE NÓMINA
        Schema::create('nominas', function (Blueprint $table) {
            $table->id();
            $table->string('codigo', 40)->unique(); // NOM-2026-10-Q1
            $table->string('titulo', 150);
            $table->string('tipo_periodo', 20)->default('quincenal'); // quincenal, mensual, extraordinaria
            $table->date('fecha_inicio');
            $table->date('fecha_fin');
            $table->date('fecha_pago');
            $table->string('estado', 20)->default('borrador'); // borrador, calculada, aprobada, pagada, anulada
            
            // Totales de cuadre general
            $table->decimal('total_ingresos', 14, 2)->default(0);
            $table->decimal('total_deducciones', 14, 2)->default(0);
            $table->decimal('total_neto', 14, 2)->default(0);
            
            $table->foreignId('realizado_por')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('aprobado_por')->nullable()->constrained('users')->nullOnDelete();
            $table->text('notas')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        // 3. DETALLE POR EMPLEADO EN LA NÓMINA (Relacionado con tabla 'empleados')
        Schema::create('nomina_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nomina_id')->constrained('nominas')->cascadeOnDelete();
            $table->foreignId('empleado_id')->constrained('empleados')->restrictOnDelete();
            
            // Snapshot salarial del momento
            $table->decimal('salario_mensual', 12, 2)->default(0);
            $table->decimal('salario_periodo', 12, 2)->default(0);
            $table->decimal('salario_hora', 10, 4)->default(0);
            $table->decimal('dias_trabajados', 5, 2)->default(15);
            $table->decimal('horas_trabajadas', 6, 2)->default(120);
            $table->decimal('horas_no_laboradas', 6, 2)->default(0);
            $table->decimal('horas_extras', 6, 2)->default(0);

            // Totales por empleado
            $table->decimal('total_ingresos', 12, 2)->default(0);
            $table->decimal('total_deducciones', 12, 2)->default(0);
            $table->decimal('neto_pagar', 12, 2)->default(0);
            
            $table->text('comentarios')->nullable();
            $table->timestamps();

            $table->unique(['nomina_id', 'empleado_id']);
        });

        // 4. CONCEPTOS DESGLOSADOS POR EMPLEADO (LÍNEAS ATÓMICAS)
        Schema::create('nomina_detalle_conceptos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nomina_detalle_id')->constrained('nomina_detalles')->cascadeOnDelete();
            $table->foreignId('concepto_id')->constrained('nomina_conceptos')->restrictOnDelete();
            $table->enum('tipo', ['ingreso', 'deduccion']);
            $table->decimal('monto', 12, 2)->default(0);
            $table->decimal('cantidad', 8, 2)->nullable(); // ej: 4 horas, 7 días
            $table->decimal('valor_unitario', 12, 2)->nullable();
            $table->string('referencia_cuota', 40)->nullable(); // ej: "13/24", "27/36", "1/2"
            $table->string('notas', 255)->nullable();
            $table->timestamps();
        });

        // 5. PRÉSTAMOS Y DESCUENTOS RECURRENTES POR EMPLEADO
        Schema::create('nomina_empleado_recurrentes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('empleado_id')->constrained('empleados')->cascadeOnDelete();
            $table->foreignId('concepto_id')->constrained('nomina_conceptos')->restrictOnDelete();
            $table->string('descripcion', 150);
            $table->decimal('monto_total', 12, 2)->default(0);
            $table->decimal('monto_cuota', 12, 2)->default(0);
            $table->integer('cuotas_totales')->default(1);
            $table->integer('cuotas_pagadas')->default(0);
            $table->decimal('saldo_restante', 12, 2)->default(0);
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nomina_empleado_recurrentes');
        Schema::dropIfExists('nomina_detalle_conceptos');
        Schema::dropIfExists('nomina_detalles');
        Schema::dropIfExists('nominas');
        Schema::dropIfExists('nomina_conceptos');
    }
};

