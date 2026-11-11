<?php

return [
    'driver' => 'jwt',
    'provider' => [
        'driver' => 'eloquent',
        'model' => App\Models\User::class,
    ],
];
