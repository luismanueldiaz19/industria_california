<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nomina_escalas_isr', function (Blueprint $table) {
            $table->id();
            $table->integer('anio')->default(2026);
            $table->decimal('desde_mensual', 12, 2)->default(0);
            $table->decimal('hasta_mensual', 12, 2)->nullable(); // null indica sin tope superior (> RD$ 72,260.26)
            $table->decimal('tasa_porcentaje', 5, 2)->default(0); // 0, 15.00, 20.00, 25.00
            $table->decimal('impuesto_base_mensual', 12, 2)->default(0); // 0, 2601.33, 6648.00
            $table->decimal('excedente_desde_mensual', 12, 2)->default(0); // 34685.00, 52027.42, 72260.25
            $table->string('descripcion', 150)->nullable();
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nomina_escalas_isr');
    }
};

