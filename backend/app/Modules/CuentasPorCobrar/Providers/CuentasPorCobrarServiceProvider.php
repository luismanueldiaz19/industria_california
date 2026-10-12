<?php

namespace App\Modules\CuentasPorCobrar\Providers;

use App\Modules\CuentasPorCobrar\Repositories\Contracts\CuentaPorCobrarRepositoryInterface;
use App\Modules\CuentasPorCobrar\Repositories\CuentaPorCobrarRepository;
use Illuminate\Support\ServiceProvider;

class CuentasPorCobrarServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            CuentaPorCobrarRepositoryInterface::class,
            CuentaPorCobrarRepository::class
        );
    }

    public function boot(): void
    {
    }
}
