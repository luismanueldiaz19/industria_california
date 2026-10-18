<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Tabla de Viajes Históricos / Despachos de Camiones Victuales
        Schema::create('camion_victual_viajes', function (Blueprint $table) {
            $table->id();
            $table->string('codigo', 30)->unique(); // Ej: VJ-0001
            $table->foreignId('camion_victual_id')->nullable()->constrained('camiones_victuales')->nullOnDelete();
            $table->foreignId('chofer_id')->constrained('choferes');
            $table->foreignId('vendedor_id')->constrained('users');
            $table->foreignId('vehiculo_id')->nullable()->constrained('vehiculos')->nullOnDelete();
            $table->dateTime('fecha_salida');
            $table->dateTime('fecha_cierre')->nullable();
            $table->foreignId('cerrado_por')->nullable()->constrained('users');
            $table->decimal('total_facturado', 14, 2)->default(0);
            $table->decimal('total_gastos', 14, 2)->default(0);
            $table->unsignedTinyInteger('cant_ayudantes')->default(0);
            $table->string('nombres_ayudantes')->nullable();
            $table->text('comentarios')->nullable();
            $table->enum('estado', ['en_ruta', 'completado', 'cancelado'])->default('en_ruta');
            $table->timestamps();
        });

        // 2. Tabla de Pedidos incluidos en cada Viaje Histórico
        Schema::create('camion_viaje_pedidos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('viaje_id')->constrained('camion_victual_viajes')->onDelete('cascade');
            $table->foreignId('pedido_id')->constrained('pedidos')->onDelete('cascade');
            $table->unsignedSmallInteger('orden_viaje')->default(0);
            $table->enum('estado_entrega', ['pendiente', 'en_curso', 'entregado', 'fallido'])->default('en_curso');
            $table->dateTime('fecha_entregado')->nullable();
            $table->text('comentario_entrega')->nullable();
            $table->decimal('total_pedido', 14, 2)->default(0);
            $table->timestamps();

            $table->unique(['viaje_id', 'pedido_id']);
        });

        // 3. Tabla de Gastos asociados a un Viaje (Combustible, Dieta, Peajes, etc.)
        Schema::create('camion_viaje_gastos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('viaje_id')->constrained('camion_victual_viajes')->onDelete('cascade');
            $table->string('tipo_gasto', 50)->default('otro'); // combustible, dieta, peaje, otro
            $table->string('concepto');
            $table->decimal('cantidad', 10, 2)->default(0); // Ej. galones de combustible
            $table->decimal('precio_unitario', 12, 2)->default(0);
            $table->decimal('monto_total', 14, 2)->default(0);
            $table->string('comprobante')->nullable();
            $table->foreignId('registrado_por')->nullable()->constrained('users');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('camion_viaje_gastos');
        Schema::dropIfExists('camion_viaje_pedidos');
        Schema::dropIfExists('camion_victual_viajes');
    }
};
