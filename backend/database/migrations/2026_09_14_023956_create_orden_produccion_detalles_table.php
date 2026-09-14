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
        Schema::create('orden_produccion_detalles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('orden_produccion_id')->constrained('orden_produccions')->onDelete('cascade');
            $table->foreignId('producto_id')->constrained('inventario_productos');
            $table->foreignId('pedido_detalle_id')->nullable()->constrained('pedido_detalles')->onDelete('set null');
            $table->decimal('cantidad_faltante', 10, 3);
            $table->decimal('cantidad_producida', 10, 3)->default(0);
            $table->enum('estado', ['pendiente', 'listo'])->default('pendiente');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orden_produccion_detalles');
    }
};
