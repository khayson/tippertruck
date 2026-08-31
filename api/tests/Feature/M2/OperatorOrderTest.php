<?php

declare(strict_types=1);

use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Order;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed();
});

function makeAssignedOrder(User $operator, User $client, OrderStatus $status = OrderStatus::Confirmed): Order
{
    $sand = SandType::firstOrFail();
    $truck = TruckType::firstOrFail();

    return Order::create([
        'order_ref' => 'TT-'.now()->format('Ymd').'-'.str_pad((string) random_int(1, 9999), 4, '0', STR_PAD_LEFT),
        'user_id' => $client->id,
        'sand_type_id' => $sand->id,
        'truck_type_id' => $truck->id,
        'price_ghs' => 1600,
        'delivery_fee_ghs' => 0,
        'total_ghs' => 1600,
        'recipient_name' => 'Ama Boateng',
        'recipient_phone' => '0241234567',
        'street_address' => '12 Demo Road',
        'region' => 'Greater Accra',
        'city' => 'Accra',
        'payment_method' => PaymentMethod::Cod,
        'payment_status' => PaymentStatus::Pending,
        'status' => $status,
        'assigned_operator_id' => $operator->id,
        'confirmed_at' => now(),
        'dispatched_at' => $status === OrderStatus::OnTheWay || $status === OrderStatus::Delivered ? now() : null,
        'delivered_at' => $status === OrderStatus::Delivered ? now() : null,
    ]);
}

test('operator can list assigned orders', function () {
    $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
    makeAssignedOrder($operator, $client);

    $this->actingAs($operator)
        ->getJson('/api/v1/operator/orders')
        ->assertStatus(200)
        ->assertJsonPath('success', true)
        ->assertJsonStructure([
            'data' => [
                'orders' => [['id', 'order_ref', 'status', 'status_label', 'delivery']],
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ],
        ]);
});

test('client cannot access operator orders', function () {
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();

    $this->actingAs($client)
        ->getJson('/api/v1/operator/orders')
        ->assertStatus(403);
});

test('operator cannot view another operators order', function () {
    $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
    $other = User::factory()->create(['role' => UserRole::Operator]);
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
    $order = makeAssignedOrder($other, $client);

    $this->actingAs($operator)
        ->getJson("/api/v1/operator/orders/{$order->id}")
        ->assertStatus(403);
});

test('operator can dispatch a confirmed assigned order', function () {
    $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
    $order = makeAssignedOrder($operator, $client, OrderStatus::Confirmed);

    $this->actingAs($operator)
        ->postJson("/api/v1/operator/orders/{$order->id}/dispatch")
        ->assertStatus(200)
        ->assertJsonPath('data.order.status', 'on_the_way');

    expect($order->fresh()->status)->toBe(OrderStatus::OnTheWay);
});

test('operator can deliver an on_the_way assigned order', function () {
    $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
    $order = makeAssignedOrder($operator, $client, OrderStatus::OnTheWay);

    $this->actingAs($operator)
        ->postJson("/api/v1/operator/orders/{$order->id}/deliver")
        ->assertStatus(200)
        ->assertJsonPath('data.order.status', 'delivered');
});

test('dispatch rejects illegal transition', function () {
    $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
    $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
    $order = makeAssignedOrder($operator, $client, OrderStatus::OnTheWay);

    $this->actingAs($operator)
        ->postJson("/api/v1/operator/orders/{$order->id}/dispatch")
        ->assertStatus(403);
});
