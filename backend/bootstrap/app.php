<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
      $exceptions->render(function (QueryException $e, $request) {
            if ($request->is('api/*')) {
                Log::error('Error de base de datos', ['mensaje' => $e->getMessage()]);

                return response()->json([
                    'message' => 'Ocurrió un error al procesar la solicitud. Intenta de nuevo.',
                ], 500);
            }
        });
    })->create();
