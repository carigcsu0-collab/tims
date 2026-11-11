<?php

use Illuminate\Support\Facades\Facade;
use Illuminate\Support\ServiceProvider;

return [
    'name' => env('APP_NAME', 'TIMS'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'timezone' => env('APP_TIMEZONE', 'UTC'),
    'url' => env('APP_URL', 'http://localhost'),
    'asset_url' => env('ASSET_URL'),
    'key' => env('APP_KEY'),
    'cipher' => 'AES-256-CBC',
    'providers' => ServiceProvider::defaultProviders()->merge([
        // Package Service Providers
    ])->toArray(),
    'aliases' => Facade::defaultAliases()->merge([
        // Example: 'Example' => App\Facades\Example::class,
    ])->toArray(),
];
