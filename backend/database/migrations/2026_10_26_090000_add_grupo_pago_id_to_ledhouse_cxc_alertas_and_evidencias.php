<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Pago agrupado: un mismo pago/comprobante que cubre varias facturas.
     * Cada factura conserva su propia alerta, pero todas comparten el mismo
     * grupo_pago_id y la misma evidencia física (ruta_archivo).
     */
    public function up(): void
    {
        Schema::table('ledhouse_cxc_alertas', function (Blueprint $table) {
            $table->uuid('grupo_pago_id')->nullable()->after('vendedor_id')->index();
        });

        Schema::table('ledhouse_cxc_evidencias', function (Blueprint $table) {
            $table->uuid('grupo_pago_id')->nullable()->after('alerta_id')->index();
        });
    }

    public function down(): void
    {
        Schema::table('ledhouse_cxc_evidencias', function (Blueprint $table) {
            $table->dropIndex(['grupo_pago_id']);
            $table->dropColumn('grupo_pago_id');
        });

        Schema::table('ledhouse_cxc_alertas', function (Blueprint $table) {
            $table->dropIndex(['grupo_pago_id']);
            $table->dropColumn('grupo_pago_id');
        });
    }
};
