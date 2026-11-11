<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;

class SettingsController extends Controller
{
    public function index()
    {
        return response()->json([
            'app_name' => config('app.name', 'TIMS'),
            'app_version' => '1.0.0',
            'organization' => 'CAGAYAN STATE UNIVERSITY-CARIG CAMPUS',
            'session_timeout_minutes' => 30,
            'default_page_size' => 15,
            'currency' => 'PHP',
            'date_format' => 'Y-m-d',
            'datetime_format' => 'Y-m-d H:i:s',
            'low_stock_threshold' => 'minimum_stock',
            'enable_borrowing' => true,
            'enable_maintenance' => true,
            'enable_reorder_alerts' => true,
        ]);
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'session_timeout_minutes' => 'nullable|integer|min:5|max:1440',
            'default_page_size' => 'nullable|integer|min:5|max:100',
            'currency' => 'nullable|string|max:10',
            'enable_borrowing' => 'nullable|boolean',
            'enable_maintenance' => 'nullable|boolean',
            'enable_reorder_alerts' => 'nullable|boolean',
        ]);

        return response()->json(array_merge(
            ['message' => 'Settings updated successfully'],
            $data
        ));
    }
}
