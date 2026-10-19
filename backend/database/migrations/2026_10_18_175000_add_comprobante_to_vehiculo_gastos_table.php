<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->string('comprobante', 100)->nullable()->after('monto_total');
        });

        // Migrar el primer comprobante del JSON al campo directo comprobante si existe
        $gastos = DB::table('vehiculo_gastos')->whereNotNull('comprobantes')->get();
        foreach ($gastos as $g) {
            $comps = json_decode($g->comprobantes, true);
            if (is_array($comps) && !empty($comps)) {
                DB::table('vehiculo_gastos')->where('id', $g->id)->update([
                    'comprobante' => (string) reset($comps),
                ]);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('vehiculo_gastos', function (Blueprint $table) {
            $table->dropColumn('comprobante');
        });
    }
};
