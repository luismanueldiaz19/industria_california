<?php

namespace App\Modules\ChequeFuturista\Providers;

use App\Modules\ChequeFuturista\Models\ChequeFuturista;
use App\Modules\ChequeFuturista\Models\DocumentoCheque;
use App\Modules\ChequeFuturista\Policies\ChequeFuturistaPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class ChequeFuturistaServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bindings futuros aqui
    }

    public function boot(): void
    {
        Gate::policy(ChequeFuturista::class, ChequeFuturistaPolicy::class);
        Gate::policy(DocumentoCheque::class, ChequeFuturistaPolicy::class);
    }
}