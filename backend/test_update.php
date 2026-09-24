<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$c = App\Modules\CamionVictual\Models\CamionVictual::find(1);
$datos = ['estado' => App\Modules\CamionVictual\Enums\EstadoCamion::from('armando')];
$c->update($datos);
var_dump($c->estado->value);

$datos = ['estado' => App\Modules\CamionVictual\Enums\EstadoCamion::from('vacio')];
$c->update($datos);
var_dump($c->estado->value);
