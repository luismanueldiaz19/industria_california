<?php

namespace App\Modules\Produccion\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Produccion\Repositories\Contracts\ProduccionRepositoryInterface;
use App\Modules\Produccion\Repositories\ProduccionRepository;

class ProduccionServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            ProduccionRepositoryInterface::class,
            ProduccionRepository::class
        );
    }

    public function boot(): void
    {
        //
    }
}
