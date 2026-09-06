<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**cla
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            RolesAndPermissionsSeeder::class,
        ]);

        // Crear usuario admin por defecto si no existe
        $adminUser = \App\Models\User::firstOrCreate(
            ['username' => 'ludeveloper'],
            [
                'name' => 'Lwader Soft S.R.L',
                'email' => 'lwadersoft@gmail.com',
                'password' => Hash::make('199512'),
            ]
        );
        
        // Asignar rol de admin
        $adminUser->assignRole('admin');

        // Crear vendedores
        $vendedores = [
            ['username' => 'wagner', 'name' => 'Wagner', 'email' => 'wagner@industriacalifornia.com'],
            ['username' => 'edward', 'name' => 'EDWARD', 'email' => 'edward@industriacalifornia.com'],
            ['username' => 'luisa', 'name' => 'Luisa', 'email' => 'luisa@industriacalifornia.com'],
            ['username' => 'claudio', 'name' => 'Claudio', 'email' => 'claudio@industriacalifornia.com'],
        ];

        foreach ($vendedores as $v) {
            $user = \App\Models\User::firstOrCreate(
                ['username' => $v['username']],
                [
                    'name' => $v['name'],
                    'email' => $v['email'],
                    'password' => Hash::make('123456'), // Contraseña por defecto
                ]
            );
            $user->assignRole('vendedor');
        }
    }
}
