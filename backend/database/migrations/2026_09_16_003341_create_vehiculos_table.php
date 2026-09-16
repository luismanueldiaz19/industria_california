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
        Schema::create('vehiculos', function (Blueprint $table) {
            $table->id();
            $table->string('ficha')->unique(); // Ej: F-119
            $table->string('placa')->nullable();
            $table->string('marca')->nullable();
            $table->string('modelo')->nullable();
            $table->integer('año')->nullable();
            $table->enum('tipo_energia', ['gasolina', 'diesel', 'electrico', 'hibrido', 'gas'])->default('diesel');
            $table->decimal('capacidad_carga', 10, 2)->nullable();
            $table->enum('estado', ['disponible', 'en_mantenimiento', 'inactivo'])->default('disponible');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehiculos');
    }
};
