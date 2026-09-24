<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = App\Models\User::first();
Auth::login($user);

$request = Illuminate\Http\Request::create('/api/v1/industria-california/camiones-victuales/1', 'PUT', [
    'estado' => 'vacio',
    'nombre' => 'Test',
    'chofer_id' => 6,
    'vendedor_id' => 1
]);

$response = app()->handle($request);

echo "STATUS: " . $response->getStatusCode() . "\n";
echo "CONTENT: " . $response->getContent();
