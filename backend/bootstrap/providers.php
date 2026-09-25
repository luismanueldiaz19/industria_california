<?php

use App\Providers\AppServiceProvider;

return [
    App\Providers\AppServiceProvider::class,
    App\Modules\Producto\Providers\ProductoServiceProvider::class,
    App\Modules\Pedido\Providers\PedidoServiceProvider::class,
    App\Modules\Produccion\Providers\ProduccionServiceProvider::class,
    App\Modules\CamionVictual\Providers\CamionVictualServiceProvider::class,
    App\Modules\Vehiculo\Providers\VehiculoServiceProvider::class,
];
