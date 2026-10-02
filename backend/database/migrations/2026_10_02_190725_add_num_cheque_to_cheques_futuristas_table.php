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
        Schema::table('cheques_futuristas', function (Blueprint $table) {
            $table->string('num_cheque', 50)->default('000000')->after('id_vendedor')->comment('Número del cheque (obligatorio)');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('cheques_futuristas', function (Blueprint $table) {
            $table->dropColumn('num_cheque');
        });
    }
};
