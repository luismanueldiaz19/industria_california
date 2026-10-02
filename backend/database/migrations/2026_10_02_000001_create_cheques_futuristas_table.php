<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cheques_futuristas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_cliente')->constrained('ledhouse_clientes')->onDelete('restrict');
            $table->foreignId('id_vendedor')->constrained('users')->onDelete('restrict');
            $table->string('num_pedido', 100)->nullable()->comment('Numero de pedido relacionado (opcional)');
            $table->enum('estado', ['pendiente', 'depositado', 'cancelado', 'vencido'])->default('pendiente');
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cheques_futuristas');
    }
};