<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\LedhouseCliente;
use App\Models\Ruta;
use App\Modules\Producto\Models\Categoria;
use App\Modules\Producto\Models\Producto;

class TestDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // 1. Obtener usuario para asignación de autor en rutas
        $admin = User::first();
        $userId = $admin ? $admin->id : 1;

        // 2. Cliente de prueba
        LedhouseCliente::firstOrCreate(
            ['documento' => '123456789'],
            [
                'id_cliente_externo' => 'CLI-TEST001',
                'nombre'             => 'Cliente de Prueba SRL',
                'whatsapp'           => '809-555-0000',
                'direccion'          => 'Calle Principal #123, Santo Domingo',
                'tipo_documento'     => 'RNC',
                'limite_credito'     => 50000,
                'dias_credito'       => 30,
            ]
        );

        // 3. Crear Categoría de prueba
        $categoria = Categoria::firstOrCreate(
            ['nombre' => 'TUBERÍAS PVC'],
            [
                'imagen_path' => null,
            ]
        );

        // 4. Crear Producto de prueba con su categoría
        Producto::firstOrCreate(
            ['codigo' => 'TUB-PVC-001'],
            [
                'category_id'     => $categoria->id,
                'descripcion'     => 'TUBO PVC PRESIÓN',
                'medidas'         => '1/2" X 19\'',
                'capacidad'       => 'SCH-40',
                'cant_x_packages' => 20,
                'unidad'          => 'TUBO',
                'costo'           => 180.00,
                'precio'          => 260.00,
                'stock'           => 150.000,
                'stock_minimo'    => 20.000,
                'stock_maximo'    => 500.000,
                'activo'          => true,
            ]
        );

        // 5. Crear 2 Rutas de prueba
        Ruta::firstOrCreate(
            ['nombre' => 'Ruta 1 - Santo Domingo'],
            [
                'chofer'       => 'Juan Pérez',
                'ficha_camion' => 'CAM-001',
                'created_by'   => $userId,
            ]
        );

        Ruta::firstOrCreate(
            ['nombre' => 'Ruta 2 - Santiago'],
            [
                'chofer'       => 'Pedro Ramírez',
                'ficha_camion' => 'CAM-002',
                'created_by'   => $userId,
            ]
        );
    }
}

