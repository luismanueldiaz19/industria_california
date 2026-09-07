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
        // Drop the check constraint created by Postgres for the original enum column
        \Illuminate\Support\Facades\DB::statement('ALTER TABLE ledhouse_cxc_alertas DROP CONSTRAINT IF EXISTS ledhouse_cxc_alertas_tipo_check');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Not recreating the constraint in down() because we already converted it to string.
    }
};
