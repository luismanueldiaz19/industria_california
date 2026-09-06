<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ledhouse_cxc_evidencias', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ledhouse_cxc_id')
                  ->constrained('ledhouse_cxcs')
                  ->onDelete('cascade');
            $table->foreignId('alerta_id')
                  ->nullable()
                  ->constrained('ledhouse_cxc_alertas')
                  ->nullOnDelete();
            $table->foreignId('subido_por')
                  ->constrained('users')
                  ->onDelete('cascade');
            $table->string('nombre_archivo');
            $table->string('ruta_archivo');
            $table->enum('tipo_archivo', ['pdf', 'jpg', 'jpeg', 'png']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ledhouse_cxc_evidencias');
    }
};
