<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder {
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // 🔐 PERMISOS
        $permisos = [

            // CLIENTES
            'ver_clientes',
            'crear_clientes',
            'editar_clientes',
            'eliminar_clientes',

            // PRODUCTOS
            'ver_productos',
            'crear_productos',
            'editar_productos',
            'eliminar_productos',

            // FACTURAS
            'ver_facturas',
            'crear_facturas',
            'editar_facturas',
            'eliminar_facturas',

            // EVENTOS / BUFFET
            'ver_eventos',
            'crear_eventos',

            // INVENTARIO
            'ver_inventario',
            'crear_inventario',
            'gestionar_recetas',

            // GASTOS
            'ver_gastos',
            'crear_gastos',

            // NOMINA
            'ver_nomina',

            // USUARIOS
            'gestionar_usuarios',
            
   
        ];

        foreach ($permisos as $permiso) {
            Permission::firstOrCreate(['name' => $permiso]);
        }

        // Obtenemos todos los permisos recién creados
        $todosLosPermisos = Permission::all();

        // 👑 1. ADMINISTRADOR (Todo el CRUD)
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->givePermissionTo($todosLosPermisos);

        // 👁️ 2. GERENTE (Solo vista de todo)
        $gerente = Role::firstOrCreate(['name' => 'gerente']);
        $permisosDeVista = $todosLosPermisos->filter(function ($permiso) {
            return str_starts_with($permiso->name, 'ver_');
        });
        $gerente->givePermissionTo($permisosDeVista);

        // 🧮 3. CONTABLE (Crea, Edita, Ve, pero NUNCA Elimina)
        $contador = Role::firstOrCreate(['name' => 'contable']);
        $permisosContador = $todosLosPermisos->filter(function ($permiso) {
            return !str_starts_with($permiso->name, 'eliminar_');
        });
        $contador->givePermissionTo($permisosContador);

        // 🧑‍💼 4. VENDEDOR (Solo ve clientes, facturas, y reporta pagos)
        $vendedor = Role::firstOrCreate(['name' => 'vendedor']);
        $vendedor->givePermissionTo([
            'ver_clientes',
            'ver_facturas',
        ]);
    }
}
