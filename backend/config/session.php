<?php

return [
    'default' => env('SESSION_DRIVER', 'database'),
    'lifetime' => env('SESSION_LIFETIME', 120),
    'encrypt' => env('SESSION_ENCRYPT', false),
    'connection' => env('SESSION_CONNECTION'),
    'table' => 'sessions',
    'store' => env('SESSION_STORE'),
    'same_site' => 'lax',
];
