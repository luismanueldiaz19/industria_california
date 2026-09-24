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
        // Drop the old constraint
        DB::statement("ALTER TABLE camiones_victuales DROP CONSTRAINT IF EXISTS camiones_victuales_estado_check");
        // Add the new constraint with 'vacio'
        DB::statement("ALTER TABLE camiones_victuales ADD CONSTRAINT camiones_victuales_estado_check CHECK (estado::text = ANY (ARRAY['vacio'::character varying, 'armando'::character varying, 'listo'::character varying, 'en_ruta'::character varying, 'cerrado'::character varying]::text[]))");
        // Set the default
        DB::statement("ALTER TABLE camiones_victuales ALTER COLUMN estado SET DEFAULT 'vacio'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement("ALTER TABLE camiones_victuales ALTER COLUMN estado SET DEFAULT 'armando'");
        DB::statement("ALTER TABLE camiones_victuales DROP CONSTRAINT IF EXISTS camiones_victuales_estado_check");
        DB::statement("ALTER TABLE camiones_victuales ADD CONSTRAINT camiones_victuales_estado_check CHECK (estado::text = ANY (ARRAY['armando'::character varying, 'listo'::character varying, 'en_ruta'::character varying, 'cerrado'::character varying]::text[]))");
    }
};
