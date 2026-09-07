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
        Schema::table('ledhouse_cxc_alertas', function (Blueprint $table) {
            $table->string('tipo')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('ledhouse_cxc_alertas', function (Blueprint $table) {
            $table->enum('tipo', ['pago_recibido', 'informacion', 'consulta'])->default('informacion')->change();
        });
    }
};
