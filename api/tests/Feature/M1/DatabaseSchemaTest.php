<?php

declare(strict_types=1);

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use App\Enums\MomoNetwork;
use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Issue;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;

uses(RefreshDatabase::class);

// --- Table existence and columns ---

test('users table has the required columns', function () {
    expect(Schema::hasColumns('users', [
        'id', 'name', 'email', 'password', 'phone', 'role',
        'remember_token', 'created_at', 'updated_at',
    ]))->toBeTrue();
});

test('sand_types table has the required columns', function () {
    expect(Schema::hasColumns('sand_types', [
        'id', 'name', 'slug', 'description', 'icon',
        'is_active', 'sort_order', 'created_at', 'updated_at',
    ]))->toBeTrue();
});

test('truck_types table has the required columns', function () {
    expect(Schema::hasColumns('truck_types', [
        'id', 'name', 'slug', 'capacity_label', 'capacity_tonnes_min',
        'capacity_tonnes_max', 'price_ghs', 'is_popular', 'is_active',
        'sort_order', 'created_at', 'updated_at',
    ]))->toBeTrue();
});

test('orders table has the required columns', function () {
    expect(Schema::hasColumns('orders', [
        'id', 'order_ref', 'user_id', 'sand_type_id', 'truck_type_id',
        'price_ghs', 'delivery_fee_ghs', 'total_ghs',
        'recipient_name', 'recipient_phone', 'street_address', 'region', 'city',
        'landmark', 'delivery_note',
        'payment_method', 'payment_status', 'momo_name', 'momo_phone', 'momo_network',
        'status', 'assigned_operator_id',
        'confirmed_at', 'dispatched_at', 'delivered_at',
        'created_at', 'updated_at',
    ]))->toBeTrue();
});

test('issues table has the required columns', function () {
    expect(Schema::hasColumns('issues', [
        'id', 'user_id', 'order_id', 'issue_type', 'description',
        'status', 'admin_response', 'resolved_at',
        'created_at', 'updated_at',
    ]))->toBeTrue();
});

test('order_status_log table has the required columns', function () {
    expect(Schema::hasColumns('order_status_log', [
        'id', 'order_id', 'old_status', 'new_status',
        'changed_by', 'note', 'created_at',
    ]))->toBeTrue();
});

// --- FK: RESTRICT on orders.user_id ---

test('deleting a user with orders fails due to restrict', function () {
    $order = Order::factory()->create();

    expect(fn () => $order->user->forceDelete())
        ->toThrow(QueryException::class);

    expect(User::find($order->user_id))->not->toBeNull();
});

// --- FK: RESTRICT on orders.sand_type_id ---

test('deleting a sand type with orders fails due to restrict', function () {
    $order = Order::factory()->create();

    expect(fn () => $order->sandType->delete())
        ->toThrow(QueryException::class);

    expect(SandType::find($order->sand_type_id))->not->toBeNull();
});

// --- FK: RESTRICT on orders.truck_type_id ---

test('deleting a truck type with orders fails due to restrict', function () {
    $order = Order::factory()->create();

    expect(fn () => $order->truckType->delete())
        ->toThrow(QueryException::class);

    expect(TruckType::find($order->truck_type_id))->not->toBeNull();
});

// --- FK: CASCADE on issues.user_id ---

test('deleting a user cascades to their issues', function () {
    $user = User::factory()->create();
    $issue = Issue::factory()->create(['user_id' => $user->id]);

    $user->forceDelete();

    expect(Issue::find($issue->id))->toBeNull();
});

// --- FK: SET NULL on issues.order_id ---

test('deleting an order sets null on related issues', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id]);
    $issue = Issue::factory()->create([
        'user_id' => $user->id,
        'order_id' => $order->id,
    ]);

    $order->forceDelete();

    expect(Issue::find($issue->id)->order_id)->toBeNull();
});

// --- FK: CASCADE on order_status_log.order_id ---

test('deleting an order cascades to its status log entries', function () {
    $order = Order::factory()->create();
    $log = OrderStatusLog::factory()->create(['order_id' => $order->id]);

    $order->forceDelete();

    expect(OrderStatusLog::find($log->id))->toBeNull();
});

// --- Enum tests ---

test('OrderStatus enum has label and progressPercent', function () {
    expect(OrderStatus::Confirmed->label())->toBe('Confirmed');
    expect(OrderStatus::Confirmed->progressPercent())->toBe(33);
    expect(OrderStatus::OnTheWay->label())->toBe('On The Way');
    expect(OrderStatus::OnTheWay->progressPercent())->toBe(66);
    expect(OrderStatus::Delivered->label())->toBe('Delivered');
    expect(OrderStatus::Delivered->progressPercent())->toBe(100);
    expect(OrderStatus::Cancelled->label())->toBe('Cancelled');
    expect(OrderStatus::Cancelled->progressPercent())->toBe(0);
});

test('all enums have the expected cases', function () {
    expect(UserRole::cases())->toHaveCount(3);
    expect(OrderStatus::cases())->toHaveCount(4);
    expect(PaymentMethod::cases())->toHaveCount(2);
    expect(PaymentStatus::cases())->toHaveCount(3);
    expect(IssueType::cases())->toHaveCount(7);
    expect(IssueStatus::cases())->toHaveCount(4);
    expect(MomoNetwork::cases())->toHaveCount(3);
});

// --- Model relationships ---

test('order belongs to user, sand type, and truck type', function () {
    $order = Order::factory()->create();

    expect($order->user)->toBeInstanceOf(User::class);
    expect($order->sandType)->toBeInstanceOf(SandType::class);
    expect($order->truckType)->toBeInstanceOf(TruckType::class);
});

test('order has many status logs', function () {
    $order = Order::factory()->create();
    OrderStatusLog::factory()->create(['order_id' => $order->id]);

    expect($order->statusLogs)->toHaveCount(1);
    expect($order->statusLogs->first())->toBeInstanceOf(OrderStatusLog::class);
});

test('user has many orders and issues', function () {
    $user = User::factory()->create();
    Order::factory()->create(['user_id' => $user->id]);
    Issue::factory()->create(['user_id' => $user->id]);

    expect($user->orders)->toHaveCount(1);
    expect($user->issues)->toHaveCount(1);
});

// --- Enum casts ---

test('order casts enums correctly', function () {
    $order = Order::factory()->create();

    expect($order->status)->toBeInstanceOf(OrderStatus::class);
    expect($order->payment_method)->toBeInstanceOf(PaymentMethod::class);
    expect($order->payment_status)->toBeInstanceOf(PaymentStatus::class);
});

test('user casts role enum', function () {
    $user = User::factory()->admin()->create();

    expect($user->role)->toBe(UserRole::Admin);
});

// --- Decimal casts ---

test('money columns are cast to decimal strings', function () {
    $order = Order::factory()->create([
        'price_ghs' => 450,
        'delivery_fee_ghs' => 0,
        'total_ghs' => 450,
    ]);

    $order->refresh();

    expect($order->price_ghs)->toBe('450.00');
    expect($order->delivery_fee_ghs)->toBe('0.00');
    expect($order->total_ghs)->toBe('450.00');
});

// --- Seeders ---

test('seeders run cleanly', function () {
    $this->seed();

    expect(SandType::count())->toBe(3);
    expect(TruckType::count())->toBe(3);
    expect(User::count())->toBe(3);
    expect(Order::count())->toBe(8);
    expect(OrderStatusLog::count())->toBeGreaterThanOrEqual(8);

    expect(User::where('role', UserRole::Admin)->count())->toBe(1);
    expect(User::where('role', UserRole::Operator)->count())->toBe(1);
    expect(User::where('role', UserRole::Client)->count())->toBe(1);

    expect(TruckType::where('is_popular', true)->first()->price_ghs)->toBe('450.00');
});

test('seeders run clean twice in a row', function () {
    $this->seed();
    $this->seed();

    expect(SandType::count())->toBe(3);
    expect(TruckType::count())->toBe(3);
});
