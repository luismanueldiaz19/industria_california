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
        Schema::table('cheques_futuristas', function (Blueprint $table) {
        // Usa 'date' o 'timestamp' según necesites hora o no.
        // Se define como 'nullable' para evitar problemas con registros existentes.
        $table->date('fecha_deposito')->nullable()->after('created_by');
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cheques_futuristas', function (Blueprint $table) {
            $table->dropColumn('fecha_deposito');
        });
    }
};
