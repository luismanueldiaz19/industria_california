<?php

use App\Models\User;

$user = User::create([
    'name' => 'Juan Perez (Vendedor Test)',
    'username' => 'juanperez',
    'password' => bcrypt('password123'),
    'email' => 'juan@test.com'
]);

$user->assignRole('vendedor');

echo "Vendedor creado con éxito.";
