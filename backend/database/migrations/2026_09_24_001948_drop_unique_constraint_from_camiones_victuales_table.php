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
        Schema::table('camiones_victuales', function (Blueprint $table) {
            $table->dropUnique(['chofer_id', 'slot_numero']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('camiones_victuales', function (Blueprint $table) {
            $table->unique(['chofer_id', 'slot_numero']);
        });
    }
};
