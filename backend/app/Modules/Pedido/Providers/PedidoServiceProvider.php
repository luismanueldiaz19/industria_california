<?php

namespace App\Modules\Pedido\Providers;

use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Policies\PedidoPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use App\Modules\Pedido\Repositories\Contracts\PedidoRepositoryInterface;
use App\Modules\Pedido\Repositories\PedidoRepository;



class PedidoServiceProvider extends ServiceProvider {



    public function register(): void {
        $this->app->bind(
            PedidoRepositoryInterface::class,
            PedidoRepository::class
        );
    }
    
     



    public function boot(): void {
        Gate::policy(Pedido::class, PedidoPolicy::class);
        // $this->loadRoutesFrom(__DIR__ . '/../routes/api.php');
    }
}