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
        Schema::table('products', function (Blueprint $table) {
            $table->string('codigo')->nullable()->unique()->after('id');
            $table->boolean('activo')->default(true)->after('category_id');
            $table->string('imagen_producto')->nullable()->after('activo');
            $table->foreignId('parent_id')->nullable()->constrained('products')->nullOnDelete()->after('imagen_producto');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropForeign(['parent_id']);
            $table->dropColumn(['codigo', 'activo', 'imagen_producto', 'parent_id']);
        });
    }
};
