<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventario_productos', function (Blueprint $table) {
            $table->id();
            $table->string('codigo')->unique();           // UPPERCASE, código único de producto
            $table->string('nombre');                     // UPPERCASE
            $table->enum('unidad', ['UNIDAD', 'LIBRA', 'KG', 'OTRO'])->default('UNIDAD');
            $table->decimal('costo', 12, 2)->default(0);
            $table->decimal('venta', 12, 2)->default(0);
            $table->decimal('stock', 12, 3)->default(0);
            $table->decimal('stock_maximo', 12, 3)->nullable();
            $table->decimal('stock_minimo', 12, 3)->nullable();
            $table->foreignId('categoria_id')
                ->nullable()
                ->constrained('inventario_categorias')
                ->nullOnDelete();
            // Imagen: path relativo en storage/app/public/inventario-productos/
            // Se sirve via /api/v1/file?path=...
            // Tamaño máximo: 1MB (validado en controller), comprimida a JPEG 80% calidad
            $table->string('imagen_producto')->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventario_productos');
    }
};
