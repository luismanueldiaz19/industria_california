<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ledhouse_cxc_alertas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ledhouse_cxc_id')
                  ->constrained('ledhouse_cxcs')
                  ->onDelete('cascade');
            $table->foreignId('vendedor_id')
                  ->constrained('users')
                  ->onDelete('cascade');
            $table->string('tipo')->default('informacion');
            $table->decimal('monto_informado', 15, 2)->nullable();
            $table->text('nota');
            $table->enum('estado_alerta', ['pendiente', 'revisada', 'procesada'])->default('pendiente');
            $table->foreignId('revisada_por')
                  ->nullable()
                  ->constrained('users')
                  ->nullOnDelete();
            $table->timestamp('fecha_revision')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ledhouse_cxc_alertas');
    }
};
