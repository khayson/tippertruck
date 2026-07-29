<?php

declare(strict_types=1);

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use App\Services\OrderStatusService;
use Database\Seeders\SandTypeSeeder;
use Database\Seeders\TruckTypeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;

uses(RefreshDatabase::class);

function validOrderPayload(array $overrides = []): array
{
    return array_merge([
        'sand_type_id' => SandType::first()->id,
        'truck_type_id' => TruckType::first()->id,
        'recipient_name' => 'Kofi Mensah',
        'recipient_phone' => '0241234567',
        'street_address' => 'No. 12 Osu Road',
        'region' => 'Greater Accra',
        'city' => 'Accra',
        'payment_method' => 'momo',
        'momo_name' => 'Kofi Mensah',
        'momo_phone' => '0241234567',
        'momo_network' => 'mtn',
    ], $overrides);
}

beforeEach(function () {
    $this->seed([
        SandTypeSeeder::class,
        TruckTypeSeeder::class,
    ]);
});

// --- Price snapshotting ---

test('order snapshots the truck price at creation time', function () {
    $user = User::factory()->create();
    $truck = TruckType::where('slug', 'medium')->first();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'truck_type_id' => $truck->id,
    ]));

    $response->assertStatus(201);
    expect($response->json('data.order.price_ghs'))->toBe('450.00');
    expect($response->json('data.order.total_ghs'))->toBe('450.00');

    $truck->update(['price_ghs' => 500]);

    $order = Order::first();
    expect($order->price_ghs)->toBe('450.00');
    expect($order->total_ghs)->toBe('450.00');
});

test('client-supplied price and total are rejected', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'price_ghs' => '999.00',
        'total_ghs' => '999.00',
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['price_ghs', 'total_ghs']);
});

// --- order_ref ---

test('order_ref is unique and correctly formatted', function () {
    $user = User::factory()->create();

    $r1 = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload());
    $r2 = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload());

    $ref1 = $r1->json('data.order.order_ref');
    $ref2 = $r2->json('data.order.order_ref');

    expect($ref1)->toMatch('/^TT-\d{8}-\d{4}$/');
    expect($ref2)->toMatch('/^TT-\d{8}-\d{4}$/');
    expect($ref1)->not->toBe($ref2);

    $seq1 = (int) substr($ref1, -4);
    $seq2 = (int) substr($ref2, -4);
    expect($seq2)->toBe($seq1 + 1);
});

test('order_ref collision triggers retry and succeeds', function () {
    $user = User::factory()->create();
    $date = now()->format('Ymd');
    $collidingRef = "TT-{$date}-0001";

    Order::factory()->create([
        'order_ref' => $collidingRef,
        'user_id' => $user->id,
    ]);

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload());

    $response->assertStatus(201);
    $ref = $response->json('data.order.order_ref');
    expect($ref)->toBe("TT-{$date}-0002");
});

// --- Status log on creation ---

test('creating an order writes exactly one status log row', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload())->assertStatus(201);

    $order = Order::first();
    $logs = $order->statusLogs;

    expect($logs)->toHaveCount(1);
    expect($logs->first()->old_status)->toBeNull();
    expect($logs->first()->new_status)->toBe(OrderStatus::Confirmed);
});

// --- Status transitions ---

test('legal transitions work and stamp the right timestamp', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::Confirmed]);
    $service = app(OrderStatusService::class);

    $order = $service->transition($order, OrderStatus::OnTheWay, $user, 'Dispatched');
    expect($order->status)->toBe(OrderStatus::OnTheWay);
    expect($order->dispatched_at)->not->toBeNull();

    $order = $service->transition($order, OrderStatus::Delivered, $user, 'Delivered');
    expect($order->status)->toBe(OrderStatus::Delivered);
    expect($order->delivered_at)->not->toBeNull();
});

test('cancel from confirmed works', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::Confirmed]);
    $service = app(OrderStatusService::class);

    $order = $service->transition($order, OrderStatus::Cancelled, $user);
    expect($order->status)->toBe(OrderStatus::Cancelled);
});

test('cancel from on_the_way works', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::OnTheWay]);
    $service = app(OrderStatusService::class);

    $order = $service->transition($order, OrderStatus::Cancelled, $user);
    expect($order->status)->toBe(OrderStatus::Cancelled);
});

test('illegal transitions are rejected with 422', function (string $from, string $to) {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::from($from)]);
    $service = app(OrderStatusService::class);

    expect(fn () => $service->transition($order, OrderStatus::from($to), $user))
        ->toThrow(ValidationException::class);
})->with([
    ['delivered', 'confirmed'],
    ['cancelled', 'on_the_way'],
    ['delivered', 'on_the_way'],
    ['cancelled', 'confirmed'],
    ['on_the_way', 'confirmed'],
    ['delivered', 'cancelled'],
]);

test('concurrent transition race is prevented by row lock', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::Confirmed]);
    $service = app(OrderStatusService::class);

    $staleOrder = Order::find($order->id);

    $service->transition($order, OrderStatus::Cancelled, $user, 'Cancel');

    expect(fn () => $service->transition($staleOrder, OrderStatus::OnTheWay, $user, 'Dispatch'))
        ->toThrow(ValidationException::class);

    $fresh = Order::find($order->id);
    expect($fresh->status)->toBe(OrderStatus::Cancelled);
    expect($fresh->statusLogs)->toHaveCount(1);
});

// --- Authorization ---

test('user A gets 403 requesting user B order', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $userB->id]);

    $response = $this->actingAs($userA)->getJson("/api/v1/orders/{$order->id}");

    $response->assertStatus(403)
        ->assertJson(['success' => false]);
});

test('admin can view any order', function () {
    $admin = User::factory()->admin()->create();
    $client = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $client->id]);

    $this->actingAs($admin)->getJson("/api/v1/orders/{$order->id}")
        ->assertStatus(200);
});

test('client cannot cancel an order that is on_the_way', function () {
    $client = User::factory()->create();
    $order = Order::factory()->onTheWay()->create(['user_id' => $client->id]);

    $response = $this->actingAs($client)->postJson("/api/v1/orders/{$order->id}/cancel");

    $response->assertStatus(403);
});

test('cancel endpoint works for confirmed order', function () {
    $client = User::factory()->create();
    $this->actingAs($client)->postJson('/api/v1/orders', validOrderPayload())->assertStatus(201);
    $order = Order::first();

    $response = $this->actingAs($client)->postJson("/api/v1/orders/{$order->id}/cancel");

    $response->assertStatus(200)
        ->assertJson([
            'success' => true,
            'data' => ['order' => ['status' => 'cancelled']],
        ]);
});

// --- MoMo validation ---

test('momo fields required when payment_method is momo', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'payment_method' => 'momo',
        'momo_name' => null,
        'momo_phone' => null,
        'momo_network' => null,
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['momo_name', 'momo_phone', 'momo_network']);
});

test('momo fields rejected when payment_method is cod', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'payment_method' => 'cod',
        'momo_name' => 'Kofi',
        'momo_phone' => '0241234567',
        'momo_network' => 'mtn',
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['momo_name', 'momo_phone', 'momo_network']);
});

test('cod order without momo fields succeeds', function () {
    $user = User::factory()->create();

    $payload = validOrderPayload([
        'payment_method' => 'cod',
    ]);
    unset($payload['momo_name'], $payload['momo_phone'], $payload['momo_network']);

    $response = $this->actingAs($user)->postJson('/api/v1/orders', $payload);

    $response->assertStatus(201);
});

// --- Inactive types ---

test('inactive sand type cannot be ordered', function () {
    $user = User::factory()->create();
    $sand = SandType::first();
    $sand->update(['is_active' => false]);

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'sand_type_id' => $sand->id,
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['sand_type_id']);
});

test('inactive truck type cannot be ordered', function () {
    $user = User::factory()->create();
    $truck = TruckType::first();
    $truck->update(['is_active' => false]);

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'truck_type_id' => $truck->id,
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['truck_type_id']);
});

// --- List and show ---

test('orders list returns only current user orders with pagination', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();
    Order::factory()->count(3)->create(['user_id' => $userA->id]);
    Order::factory()->count(2)->create(['user_id' => $userB->id]);

    $response = $this->actingAs($userA)->getJson('/api/v1/orders');

    $response->assertStatus(200)
        ->assertJsonCount(3, 'data.orders')
        ->assertJsonStructure(['data' => ['orders', 'meta' => ['current_page', 'last_page', 'per_page', 'total']]]);
});

test('orders list filters by status', function () {
    $user = User::factory()->create();
    Order::factory()->count(2)->create(['user_id' => $user->id, 'status' => OrderStatus::Confirmed]);
    Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::Delivered]);

    $response = $this->actingAs($user)->getJson('/api/v1/orders?status=confirmed');

    $response->assertStatus(200)
        ->assertJsonCount(2, 'data.orders');
});

test('orders list with invalid status returns 422', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->getJson('/api/v1/orders?status=bogus');

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['status']);
});

test('orders list with empty status returns all orders', function () {
    $user = User::factory()->create();
    Order::factory()->count(2)->create(['user_id' => $user->id, 'status' => OrderStatus::Confirmed]);
    Order::factory()->create(['user_id' => $user->id, 'status' => OrderStatus::Delivered]);

    $response = $this->actingAs($user)->getJson('/api/v1/orders?status=');

    $response->assertStatus(200)
        ->assertJsonCount(3, 'data.orders');
});

test('order show includes status_log', function () {
    $user = User::factory()->create();
    $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload())->assertStatus(201);
    $order = Order::first();

    $response = $this->actingAs($user)->getJson("/api/v1/orders/{$order->id}");

    $response->assertStatus(200)
        ->assertJsonStructure([
            'data' => ['order' => ['status_log' => [['old_status', 'new_status', 'created_at']]]],
        ]);
});

test('order resource masks momo phone', function () {
    $user = User::factory()->create();
    $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload())->assertStatus(201);
    $order = Order::first();

    $response = $this->actingAs($user)->getJson("/api/v1/orders/{$order->id}");

    $momoPhone = $response->json('data.order.payment.momo_phone');
    expect($momoPhone)->toBe('024*****67');
});

// --- PIN rejection ---

test('request with pin field is rejected', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', validOrderPayload([
        'pin' => '1234',
    ]));

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['pin']);
});
