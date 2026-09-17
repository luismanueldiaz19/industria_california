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
        Schema::table('pedido_detalles', function (Blueprint $table) {
            $table->dropForeign(['product_id']);
            $table->renameColumn('product_id', 'producto_id');
            $table->foreign('producto_id')->references('id')->on('products');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pedido_detalles', function (Blueprint $table) {
            $table->dropForeign(['producto_id']);
            $table->renameColumn('producto_id', 'product_id');
            $table->foreign('product_id')->references('id')->on('products');
        });
    }
};
