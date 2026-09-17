<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            
            $table->foreignId('category_id')
                  ->constrained('categories')
                  ->cascadeOnDelete();

            $table->integer('cant_x_packages');       // 600, 300, 150...
            $table->string('descripcion');            // codo, coupling, tee, yee
            $table->string('medidas');                // 1/2 X 90, 3/4, 1 1/2...
            $table->string('capacidad')->nullable();  // presion, Drenage
            $table->string('unidad')->default('unidad');
            $table->decimal('precio', 10, 2);

            // Campos para manejo de inventario
            $table->decimal('costo', 10, 2)->default(0);
            $table->decimal('stock', 10, 2)->default(0);
            $table->decimal('stock_minimo', 10, 2)->nullable();
            $table->decimal('stock_maximo', 10, 2)->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
