<?php

namespace App\Modules\Producto\Providers;

use Illuminate\Support\ServiceProvider;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;
use App\Modules\Producto\Repositories\ProductoRepository;
use Illuminate\Support\Facades\Route;

class ProductoServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            ProductoRepositoryInterface::class,
            ProductoRepository::class
        );
        $this->app->bind(
            \App\Modules\Producto\Repositories\Contracts\CategoriaRepositoryInterface::class,
            \App\Modules\Producto\Repositories\CategoriaRepository::class
        );
    }

    public function boot(): void
    {
        $this->loadRoutesFrom(__DIR__ . '/../routes/api.php');
    }
}
