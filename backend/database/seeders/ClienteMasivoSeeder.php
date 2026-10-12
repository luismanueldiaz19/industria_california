<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ClienteMasivoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     * Inserta 10,000 clientes de prueba optimizado por lotes (chunks).
     */
    public function run(): void
    {
        $this->command->info('Iniciando generación de 10,000 clientes...');

        $nombres = [
            'Juan', 'Pedro', 'María', 'José', 'Carlos', 'Ana', 'Luis', 'Rosa', 'Manuel', 'Carmen',
            'Francisco', 'Laura', 'David', 'Elena', 'Jorge', 'Patricia', 'Roberto', 'Marta', 'Miguel', 'Sofía',
            'Alejandro', 'Lucía', 'Fernando', 'Andrea', 'Ricardo', 'Camila', 'Daniel', 'Valeria', 'Eduardo', 'Paola',
            'Gabriel', 'Daniela', 'Héctor', 'Natalia', 'Javier', 'Adriana', 'Rafael', 'Verónica', 'Andrés', 'Gabriela'
        ];

        $apellidos = [
            'Rodríguez', 'González', 'Hernández', 'Pérez', 'García', 'Martínez', 'Sánchez', 'Díaz', 'Gómez', 'Álvarez',
            'Fernández', 'López', 'Jiménez', 'Ramírez', 'Torres', 'Castro', 'Vargas', 'Reyes', 'Morales', 'Ortiz',
            'Cruz', 'Flores', 'Guzmán', 'Mendoza', 'Castillo', 'Peña', 'Santos', 'Bautista', 'Núñez', 'Medina'
        ];

        $negocios = [
            'Ferretería', 'Comercial', 'Distribuidora', 'Importadora', 'Repuestos',
            'Almacenes', 'Suministros', 'Inversiones', 'Soluciones LED', 'Auto Decoraciones'
        ];

        $ciudades = [
            'Santo Domingo', 'Santiago', 'La Vega', 'San Cristóbal', 'Puerto Plata',
            'San Pedro de Macorís', 'La Romana', 'Higüey', 'Moca', 'Bonao'
        ];

        $total = 10000;
        $chunkSize = 1000;
        $now = Carbon::now()->toDateTimeString();

        // Obtener el último ID externo numérico para evitar colisiones
        $ultimoIdExterno = DB::table('ledhouse_clientes')
            ->where('id_cliente_externo', 'LIKE', 'CLI-%')
            ->count();

        $startOffset = $ultimoIdExterno + 1;

        $batch = [];
        for ($i = 0; $i < $total; $i++) {
            $num = $startOffset + $i;
            $code = 'CLI-' . str_pad($num, 6, '0', STR_PAD_LEFT);

            // 60% personas, 40% empresas
            if ($i % 5 < 3) {
                $nombreCliente = $nombres[array_rand($nombres)] . ' ' . $apellidos[array_rand($apellidos)];
                $tipoDoc = 'Cédula';
                $documento = '402-' . str_pad(mt_rand(1, 9999999), 7, '0', STR_PAD_LEFT) . '-' . mt_rand(1, 9);
            } else {
                $nombreCliente = $negocios[array_rand($negocios)] . ' ' . $apellidos[array_rand($apellidos)] . ' S.R.L.';
                $tipoDoc = 'RNC';
                $documento = '1-3' . str_pad(mt_rand(1, 9999999), 7, '0', STR_PAD_LEFT);
            }

            $ciudad = $ciudades[array_rand($ciudades)];
            $calleNum = mt_rand(1, 150);
            $direccion = "Calle " . mt_rand(1, 30) . " #" . $calleNum . ", " . $ciudad;

            $telPrefix = ['809', '829', '849'][array_rand(['809', '829', '849'])];
            $whatsapp = $telPrefix . str_pad(mt_rand(1000000, 9999999), 7, '0', STR_PAD_LEFT);

            $limites = [0, 5000, 10000, 25000, 50000, 100000, 150000, 250000];
            $dias = [0, 15, 30, 45, 60];

            // Coordenadas aproximadas en Rep. Dominicana
            $lat = 18.450000 + (mt_rand(-50000, 50000) / 1000000);
            $lng = -69.930000 + (mt_rand(-50000, 50000) / 1000000);

            $batch[] = [
                'id_cliente_externo' => $code,
                'nombre'             => $nombreCliente,
                'whatsapp'           => $whatsapp,
                'direccion'          => $direccion,
                'tipo_documento'     => $tipoDoc,
                'documento'          => $documento,
                'limite_credito'     => $limites[array_rand($limites)],
                'dias_credito'       => $dias[array_rand($dias)],
                'latitud'            => round($lat, 7),
                'longitud'           => round($lng, 7),
                'created_at'         => $now,
                'updated_at'         => $now,
            ];

            if (count($batch) >= $chunkSize) {
                DB::table('ledhouse_clientes')->insertOrIgnore($batch);
                $batch = [];
                $insertados = $i + 1;
                $this->command->info("Insertados {$insertados} / {$total} clientes...");
            }
        }

        if (!empty($batch)) {
            DB::table('ledhouse_clientes')->insertOrIgnore($batch);
        }

        $this->command->info('¡10,000 clientes creados exitosamente!');
    }
}
