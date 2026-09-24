<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Tabla pivot entre camiones victuales y pedidos.
     * El vendedor define el orden de entrega (orden_viaje).
     * Solo pedidos en estado 'facturado' pueden ser asignados.
     */
    public function up(): void
    {
        Schema::create('camion_victual_pedido', function (Blueprint $table) {
            $table->id();
            $table->foreignId('camion_victual_id')->constrained('camiones_victuales')->onDelete('cascade');
            $table->foreignId('pedido_id')->constrained('pedidos')->onDelete('cascade');

            // El vendedor ordena los pedidos: 1 = primero en entregar, 2 = segundo, etc.
            // Se puede reordenar drag-and-drop mientras el camión esté en 'armando'
            $table->unsignedSmallInteger('orden_viaje')->default(0);

            // Estado de entrega individual del pedido dentro del camión
            $table->enum('estado_entrega', ['pendiente', 'en_curso', 'entregado', 'fallido'])->default('pendiente');

            $table->text('comentario_entrega')->nullable();
            $table->dateTime('fecha_entregado')->nullable(); // Cuándo se marcó como entregado
            $table->timestamps();

            // Un pedido solo puede estar en UN camión victual activo a la vez
            $table->unique('pedido_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('camion_victual_pedido');
    }
};
