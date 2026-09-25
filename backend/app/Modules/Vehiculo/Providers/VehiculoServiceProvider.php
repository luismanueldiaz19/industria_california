<?php

namespace App\Modules\Vehiculo\Providers;

use Illuminate\Support\ServiceProvider;

class VehiculoServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bindings de repositorios si se agregan en el futuro
    }

    public function boot(): void
    {
        // Politicas se registran aqui si se agregan
        // Gate::policy(Vehiculo::class, VehiculoPolicy::class);
    }
}
