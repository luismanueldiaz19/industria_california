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
            $table->decimal('minimo_salida', 10, 2)->default(5000.00)->after('estado');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('camiones_victuales', function (Blueprint $table) {
            $table->dropColumn('minimo_salida');
        });
    }
};
