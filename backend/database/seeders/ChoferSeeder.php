<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Chofer;
use Illuminate\Support\Facades\Hash;

class ChoferSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $choferes = [
            [
                'name' => 'Juan Pérez',
                'username' => 'juanperez',
                'email' => 'juan.perez@example.com',
                'licencia' => '001-1234567-8',
                'estado' => 'activo'
            ],
            [
                'name' => 'Pedro Ramírez',
                'username' => 'pedroramirez',
                'email' => 'pedro.ramirez@example.com',
                'licencia' => '001-8765432-1',
                'estado' => 'vacaciones'
            ],
            [
                'name' => 'Luis Guzmán',
                'username' => 'luisguzman',
                'email' => 'luis.guzman@example.com',
                'licencia' => '402-1111111-1',
                'estado' => 'activo'
            ],
        ];

        foreach ($choferes as $data) {
            // Crear el usuario primero
            $user = User::firstOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'username' => $data['username'],
                    'password' => Hash::make('password123'),
                ]
            );

            // Crear el perfil de chofer
            Chofer::firstOrCreate(
                ['user_id' => $user->id],
                [
                    'numero_licencia' => $data['licencia'],
                    'estado' => $data['estado'],
                ]
            );
        }
    }
}
