<?php

namespace App\Modules\CamionVictual\Providers;

use App\Modules\CamionVictual\Models\CamionVictual;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class CamionVictualServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Aquí se pueden registrar bindings de repositorios si se agregan en el futuro
    }

    public function boot(): void
    {
        // Las políticas se registran aquí si se agregan
        // Gate::policy(CamionVictual::class, CamionVictualPolicy::class);
    }
}
