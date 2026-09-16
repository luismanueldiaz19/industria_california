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
        Schema::create('vehiculo_gastos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehiculo_id')->constrained('vehiculos')->onDelete('cascade');
            $table->date('fecha_gasto');
            $table->string('concepto');
            $table->decimal('cantidad', 10, 2)->default(0);
            $table->string('unidad_medida')->nullable(); // ej. galones, kwh
            $table->decimal('precio_unitario', 12, 2)->default(0);
            $table->decimal('monto_total', 12, 2)->default(0);
            $table->json('comprobantes')->nullable(); // Multiple files (facturas, tickets)
            $table->foreignId('registrado_por')->nullable()->constrained('users');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehiculo_gastos');
    }
};
