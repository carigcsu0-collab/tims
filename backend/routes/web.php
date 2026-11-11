<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json(['name' => 'TIMS API', 'version' => '1.0.0']);
});
