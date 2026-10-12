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
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement("ALTER TABLE pedidos DROP CONSTRAINT IF EXISTS pedidos_estado_check;");
            DB::statement("ALTER TABLE pedidos ADD CONSTRAINT pedidos_estado_check CHECK (estado::text = ANY (ARRAY['borrador'::text, 'enviado'::text, 'facturado'::text, 'cancelado'::text, 'entregado'::text, 'cotizacion'::text]));");
        } else {
            Schema::table('pedidos', function (Blueprint $table) {
                $table->enum('estado', ['borrador', 'enviado', 'facturado', 'cancelado', 'entregado', 'cotizacion'])->default('borrador')->change();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement("ALTER TABLE pedidos DROP CONSTRAINT IF EXISTS pedidos_estado_check;");
            DB::statement("ALTER TABLE pedidos ADD CONSTRAINT pedidos_estado_check CHECK (estado::text = ANY (ARRAY['borrador'::text, 'enviado'::text, 'facturado'::text, 'cancelado'::text, 'entregado'::text]));");
        } else {
            Schema::table('pedidos', function (Blueprint $table) {
                $table->enum('estado', ['borrador', 'enviado', 'facturado', 'cancelado', 'entregado'])->default('borrador')->change();
            });
        }
    }
};
