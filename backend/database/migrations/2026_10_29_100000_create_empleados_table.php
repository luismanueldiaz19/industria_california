<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('empleados', function (Blueprint $table) {
            $table->id();
            $table->string('cedula', 20)->unique();
            $table->string('nombres', 100);
            $table->string('apellidos', 100);
            $table->string('ocupacion', 120)->nullable();
            $table->string('departamento', 80)->nullable();
            $table->string('telefono', 30)->nullable();
            $table->string('email', 120)->nullable();
            $table->text('direccion')->nullable();
            
            // Salarios base
            $table->decimal('salario_mensual', 12, 2)->default(0);
            $table->decimal('salario_quincenal', 12, 2)->default(0);
            $table->decimal('salario_hora', 10, 4)->default(0); // salario_mensual / 23.83 / 8

            // Banderas legales (TSS e Impuestos)
            $table->boolean('aplica_afp')->default(true);
            $table->boolean('aplica_ars')->default(true);
            $table->boolean('aplica_isr')->default(true);

            // Método de pago
            $table->string('tipo_pago', 30)->default('transferencia'); // transferencia, efectivo, cheque
            $table->string('banco', 60)->nullable();
            $table->string('numero_cuenta', 50)->nullable();

            // Estado y fechas
            $table->string('estado', 20)->default('activo'); // activo, inactivo, vacaciones, licencia
            $table->date('fecha_ingreso')->nullable();
            $table->date('fecha_salida')->nullable();

            // Auditoría
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('empleados');
    }
};

