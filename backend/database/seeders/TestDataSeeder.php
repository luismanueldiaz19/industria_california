<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\InventarioProducto;
use App\Models\LedhouseCliente;
use App\Models\Ruta;

class TestDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // 1. Crear un Cliente de prueba
        LedhouseCliente::firstOrCreate(
            ['documento' => '123456789'],
            [
                'nombre' => 'Cliente de Prueba',
                'whatsapp' => '809-555-0000',
                'direccion' => 'Calle Falsa 123',
                'limite_credito' => 50000,
                'dias_credito' => 30,
            ]
        );

        // 2. Crear un Producto de prueba
        InventarioProducto::firstOrCreate(
            ['codigo' => 'PROD-TEST'],
            [
                'nombre' => 'Producto de Prueba',
                'unidad' => 'UNIDAD',
                'costo' => 500.00,
                'venta' => 750.00,
                'stock' => 100,
                'stock_maximo' => 500,
                'stock_minimo' => 10,
                'activo' => true,
            ]
        );

        // 3. Crear una Ruta de prueba
        Ruta::firstOrCreate(
            ['nombre' => 'Ruta de Prueba'],
            [
                'chofer' => 'Chofer de Prueba',
                'ficha_camion' => 'CAM-001',
                'created_by' => 1,
            ]
        );
    }
}
