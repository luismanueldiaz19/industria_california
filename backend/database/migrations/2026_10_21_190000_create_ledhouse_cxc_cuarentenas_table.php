<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cuarentena de CXC: facturas retiradas de ledhouse_cxcs que deben
     * resolverse como Nota de Crédito / Débito en otro sistema.
     */
    public function up(): void
    {
        Schema::create('ledhouse_cxc_cuarentenas', function (Blueprint $table) {
            $table->id();

            // Referencia a la CXC original (sin FK porque la CXC se elimina)
            $table->unsignedBigInteger('cxc_id_original')->nullable()->index();
            $table->string('documento')->index();

            $table->foreignId('cliente_id')->nullable()->constrained('ledhouse_clientes')->nullOnDelete();
            $table->string('cliente_nombre')->nullable();
            $table->foreignId('vendedor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('vendedor_nombre')->nullable();

            $table->date('fecha_factura')->nullable();
            $table->date('fecha_vencimiento')->nullable();
            $table->decimal('monto_factura', 15, 2)->default(0);
            $table->decimal('monto_pagado', 15, 2)->default(0);
            $table->decimal('monto_pendiente', 15, 2)->default(0);

            // Nota a generar en el otro sistema
            $table->string('tipo_nota');                 // credito | debito
            $table->decimal('monto_nota', 15, 2);
            $table->string('motivo');                    // devolucion | descuento | ...
            $table->text('justificacion');
            $table->string('estado')->default('pendiente')->index(); // pendiente | aplicada | anulada

            // Resolución
            $table->string('numero_nota_externa')->nullable();
            $table->text('nota_resolucion')->nullable();
            $table->timestamp('fecha_resolucion')->nullable();

            // Historial completo de la CXC (soportes, alertas, evidencias)
            $table->json('snapshot')->nullable();

            $table->foreignId('enviado_por')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('resuelto_por')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ledhouse_cxc_cuarentenas');
    }
};
