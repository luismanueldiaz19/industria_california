<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tabla de configuración global del sistema.
     * Almacena el monto mínimo requerido para que un camión victual pueda salir.
     * Otros parámetros de sistema pueden agregarse aquí.
     */
    public function up(): void
    {
        Schema::create('configuracion_sistema', function (Blueprint $table) {
            $table->id();
            $table->string('clave')->unique(); // ej: 'camion_victual_monto_minimo'
            $table->text('valor');             // ej: '5000.00'
            $table->string('descripcion')->nullable();
            $table->timestamps();
        });

        // Valor inicial: monto mínimo de $5,000.00 para salir a logística
        DB::table('configuracion_sistema')->insert([
            'clave'       => 'camion_victual_monto_minimo',
            'valor'       => '300000.00',
            'descripcion' => 'Monto mínimo requerido (en moneda local) para que un camión victual quede listo para salir a logística.',
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('configuracion_sistema');
    }
};
