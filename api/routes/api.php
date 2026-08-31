<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChatbotController;
use App\Http\Controllers\Api\V1\ConfigController;
use App\Http\Controllers\Api\V1\IssueController;
use App\Http\Controllers\Api\V1\Operator\OrderController as OperatorOrderController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Middleware\EnsureOperator;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('auth/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
    Route::post('auth/social', [AuthController::class, 'social'])->middleware('throttle:social');

    Route::get('config', ConfigController::class);

    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);

        Route::post('orders', [OrderController::class, 'store']);
        Route::get('orders', [OrderController::class, 'index']);
        Route::get('orders/{order}', [OrderController::class, 'show']);
        Route::post('orders/{order}/cancel', [OrderController::class, 'cancel']);

        Route::post('issues', [IssueController::class, 'store']);
        Route::get('issues', [IssueController::class, 'index']);

        Route::post('chatbot/message', [ChatbotController::class, 'message']);

        Route::prefix('operator')->middleware(EnsureOperator::class)->group(function () {
            Route::get('orders', [OperatorOrderController::class, 'index']);
            Route::get('orders/{order}', [OperatorOrderController::class, 'show']);
            Route::post('orders/{order}/dispatch', [OperatorOrderController::class, 'dispatch']);
            Route::post('orders/{order}/deliver', [OperatorOrderController::class, 'deliver']);
        });
    });
});
