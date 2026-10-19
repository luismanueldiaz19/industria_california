<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->unsignedBigInteger('vehiculo_id')->nullable()->change();
        });

        // Insertar tipos de gastos base para agilizar el registro
        $tipos = [
            'COMBUSTIBLES',
            'DIETA',
            'MATERIALES Y SUMINISTROS',
            'MANTENIMIENTO Y REPARACIONES',
            'HERRAMIENTAS Y EQUIPOS',
            'PEAJE',
            'LIMPIEZA Y ASEO',
            'SERVICIOS Y UTILIDADES',
            'OTROS',
        ];

        foreach ($tipos as $tipo) {
            DB::table('tipo_gastos')->updateOrInsert(
                ['nombre' => $tipo],
                ['created_at' => now(), 'updated_at' => now()]
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->unsignedBigInteger('vehiculo_id')->nullable(false)->change();
        });
    }
};
