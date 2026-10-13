<?php

namespace App\Modules\Alerta\Providers;

use App\Modules\Alerta\Services\AlertaService;
use Illuminate\Support\ServiceProvider;

class AlertaServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(AlertaService::class, function () {
            return new AlertaService();
        });
    }

    public function boot(): void
    {
        // Registro de políticas u observadores si se requieren
    }
}
