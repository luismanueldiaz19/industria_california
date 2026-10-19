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
        // 1. Agregar viaje_id a la tabla centralizada de vehiculo_gastos
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->foreignId('viaje_id')
                ->nullable()
                ->after('vehiculo_id')
                ->constrained('camion_victual_viajes')
                ->onDelete('cascade');
        });

        // 2. Migrar los registros existentes de camion_viaje_gastos a vehiculo_gastos
        if (Schema::hasTable('camion_viaje_gastos')) {
            $viajeGastos = DB::table('camion_viaje_gastos')->get();
            foreach ($viajeGastos as $vg) {
                $viaje = DB::table('camion_victual_viajes')->where('id', $vg->viaje_id)->first();
                DB::table('vehiculo_gastos')->insert([
                    'viaje_id'        => $vg->viaje_id,
                    'vehiculo_id'     => $viaje?->vehiculo_id,
                    'fecha_gasto'     => $vg->created_at ? substr($vg->created_at, 0, 10) : now()->toDateString(),
                    'tipo_gasto'      => strtoupper($vg->tipo_gasto),
                    'concepto'        => strtoupper($vg->concepto),
                    'cantidad'        => $vg->cantidad ?? 1,
                    'unidad_medida'   => 'UNIDAD',
                    'precio_unitario' => $vg->precio_unitario ?? $vg->monto_total,
                    'monto_total'     => $vg->monto_total,
                    'comprobantes'    => $vg->comprobante ? json_encode([$vg->comprobante]) : null,
                    'registrado_por'  => $vg->registrado_por,
                    'created_at'      => $vg->created_at ?? now(),
                    'updated_at'      => $vg->updated_at ?? now(),
                ]);
            }

            // 3. Eliminar la tabla redundante
            Schema::dropIfExists('camion_viaje_gastos');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Re-crear camion_viaje_gastos
        if (!Schema::hasTable('camion_viaje_gastos')) {
            Schema::create('camion_viaje_gastos', function (Blueprint $table) {
                $table->id();
                $table->foreignId('viaje_id')->constrained('camion_victual_viajes')->onDelete('cascade');
                $table->string('tipo_gasto', 50)->default('otro');
                $table->string('concepto');
                $table->decimal('cantidad', 10, 2)->default(0);
                $table->decimal('precio_unitario', 12, 2)->default(0);
                $table->decimal('monto_total', 14, 2)->default(0);
                $table->string('comprobante')->nullable();
                $table->foreignId('registrado_por')->nullable()->constrained('users');
                $table->timestamps();
            });
        }

        // Eliminar viaje_id de vehiculo_gastos
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->dropForeign(['viaje_id']);
            $table->dropColumn('viaje_id');
        });
    }
};
