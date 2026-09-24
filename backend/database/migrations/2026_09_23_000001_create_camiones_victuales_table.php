<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Tabla principal de Camiones Victuales.
     * Cada chofer puede tener hasta 4 camiones victuales simultáneos.
     * El vendedor es quien carga los pedidos en el camión.
     */
    public function up(): void
    {
        Schema::create('camiones_victuales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('chofer_id')->constrained('choferes')->onDelete('cascade');
            $table->foreignId('vendedor_id')->constrained('users'); // Quien llena el camión
            $table->string('nombre'); // Ej: "Camión 1", "Camión Norte"
            $table->unsignedTinyInteger('slot_numero')->default(1); // Slot 1,2,3 o 4 del chofer

            // Estado del camión victual
            // armando  → el vendedor está añadiendo pedidos
            // listo    → superó el monto mínimo, listo para logística
            // en_ruta  → logística lo puso en movimiento
            // cerrado  → todos los pedidos entregados/fallidos
            $table->enum('estado', ['armando', 'listo', 'en_ruta', 'cerrado'])->default('armando');

            $table->decimal('monto_total', 12, 2)->default(0);   // Suma calculada de pedidos asignados
            $table->dateTime('fecha_cierre')->nullable();         // Cuando logística cierra el camión
            $table->foreignId('cerrado_por')->nullable()->constrained('users');
            $table->text('notas')->nullable();
            $table->timestamps();

            // Un chofer no puede tener dos camiones con el mismo slot activos al mismo tiempo
            $table->unique(['chofer_id', 'slot_numero']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('camiones_victuales');
    }
};
