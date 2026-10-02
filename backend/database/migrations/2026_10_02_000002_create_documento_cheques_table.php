<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('documento_cheques', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cheque_futurista_id')
                  ->constrained('cheques_futuristas')
                  ->onDelete('cascade')
                  ->comment('Cheque futurista al que pertenece este documento');
            $table->string('nombre_archivo')->comment('Nombre original del archivo subido');
            $table->string('ruta_archivo')->comment('Ruta relativa en storage/app/public');
            $table->enum('tipo_archivo', ['pdf', 'jpg', 'jpeg', 'png'])->comment('Tipo/extension del archivo');
            $table->foreignId('created_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('documento_cheques');
    }
};