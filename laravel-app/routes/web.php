<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

Route::get('/', function () {
    return view('welcome');
});

// Health check endpoint
Route::get('/health', function () {
    $status = [
        'status' => 'healthy',
        'timestamp' => now()->toISOString(),
        'services' => []
    ];

    // Check database connection
    try {
        DB::connection()->getPdo();
        $status['services']['database'] = 'healthy';
    } catch (Exception $e) {
        $status['services']['database'] = 'unhealthy';
        $status['status'] = 'unhealthy';
    }

    // Check cache connection
    try {
        Cache::put('health_check', 'ok', 10);
        $cacheValue = Cache::get('health_check');
        $status['services']['cache'] = $cacheValue === 'ok' ? 'healthy' : 'unhealthy';
    } catch (Exception $e) {
        $status['services']['cache'] = 'unhealthy';
        $status['status'] = 'unhealthy';
    }

    // Check storage permissions
    $storagePath = storage_path('logs');
    $status['services']['storage'] = is_writable($storagePath) ? 'healthy' : 'unhealthy';
    
    if ($status['services']['storage'] === 'unhealthy') {
        $status['status'] = 'unhealthy';
    }

    $httpStatus = $status['status'] === 'healthy' ? 200 : 503;

    return response()->json($status, $httpStatus);
});
