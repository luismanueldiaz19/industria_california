<?php

namespace App\Modules\Cliente\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Cliente\Repositories\Contracts\ClienteRepositoryInterface;
use App\Modules\Cliente\Repositories\ClienteRepository;

class ClienteServiceProvider extends ServiceProvider
{
    public function register(): void {
        $this->app->bind(
            ClienteRepositoryInterface::class,
            ClienteRepository::class
        );
    }

    public function boot(): void
    {
        // Las rutas del módulo Cliente se direccionan en backend/routes/api.php
    }
}
