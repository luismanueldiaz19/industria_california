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
        Schema::create('pedidos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cliente_id')->constrained('ledhouse_clientes');
            $table->foreignId('ruta_id')->nullable()->constrained('rutas');
            $table->foreignId('vendedor_id')->constrained('users');
            $table->foreignId('facturador_id')->nullable()->constrained('users');
            $table->enum('estado', ['borrador', 'enviado', 'facturado', 'cancelado'])->default('borrador');
            $table->text('comentario')->nullable();
            $table->decimal('total', 12, 2)->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pedidos');
    }
};
