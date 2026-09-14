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
        Schema::create('orden_produccions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pedido_id')->nullable()->constrained('pedidos')->onDelete('cascade');
            $table->foreignId('cliente_id')->constrained('ledhouse_clientes');
            $table->foreignId('vendedor_id')->constrained('users');
            $table->enum('estado', ['pendiente', 'en_proceso', 'lista', 'entregada', 'cancelada'])->default('pendiente');
            $table->date('fecha_estimada_entrega')->nullable();
            $table->text('notas')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orden_produccions');
    }
};
