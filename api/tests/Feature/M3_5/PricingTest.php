<?php

declare(strict_types=1);

use App\Models\DeliveryZone;
use App\Models\Order;
use App\Models\SandTruckPrice;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use App\Services\PricingService;
use Database\Seeders\DeliveryZoneSeeder;
use Database\Seeders\SandTruckPriceSeeder;
use Database\Seeders\SandTypeSeeder;
use Database\Seeders\TruckTypeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed([
        SandTypeSeeder::class,
        TruckTypeSeeder::class,
        SandTruckPriceSeeder::class,
        DeliveryZoneSeeder::class,
    ]);
});

// --- 9 sand/truck quote combinations ---

test('pricing service returns correct price for all 9 sand/truck combinations', function () {
    $service = app(PricingService::class);

    $expected = [
        ['Filling Sand', 'small', '900.00'],
        ['Filling Sand', 'medium', '1600.00'],
        ['Filling Sand', 'large', '2400.00'],
        ['Quarry Sand', 'small', '1100.00'],
        ['Quarry Sand', 'medium', '1900.00'],
        ['Quarry Sand', 'large', '2800.00'],
        ['River Sand', 'small', '1300.00'],
        ['River Sand', 'medium', '2300.00'],
        ['River Sand', 'large', '3100.00'],
    ];

    foreach ($expected as [$sandName, $truckSlug, $price]) {
        $sand = SandType::where('name', $sandName)->first();
        $truck = TruckType::where('slug', $truckSlug)->first();

        $quote = $service->quote($sand, $truck, 'Greater Accra');

        expect($quote['price_ghs'])->toBe($price, "Price for {$sandName} + {$truckSlug}")
            ->and($quote['delivery_fee_ghs'])->toBe('0.00')
            ->and($quote['total_ghs'])->toBe($price);
    }
});

// --- Surcharge tests ---

test('Central region adds 400 surcharge', function () {
    $service = app(PricingService::class);
    $sand = SandType::where('name', 'Filling Sand')->first();
    $truck = TruckType::where('slug', 'small')->first();

    $quote = $service->quote($sand, $truck, 'Central');

    expect($quote['price_ghs'])->toBe('900.00')
        ->and($quote['delivery_fee_ghs'])->toBe('400.00')
        ->and($quote['total_ghs'])->toBe('1300.00');
});

test('Greater Accra has zero surcharge', function () {
    $service = app(PricingService::class);
    $sand = SandType::where('name', 'Filling Sand')->first();
    $truck = TruckType::where('slug', 'small')->first();

    $quote = $service->quote($sand, $truck, 'Greater Accra');

    expect($quote['delivery_fee_ghs'])->toBe('0.00')
        ->and($quote['total_ghs'])->toBe('900.00');
});

// --- Unserved region → 422 ---

test('unserved region throws validation exception', function () {
    $service = app(PricingService::class);
    $sand = SandType::first();
    $truck = TruckType::first();

    expect(fn () => $service->quote($sand, $truck, 'Ashanti'))
        ->toThrow(ValidationException::class);
});

test('ordering to unserved region returns 422', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', [
        'sand_type_id' => SandType::first()->id,
        'truck_type_id' => TruckType::first()->id,
        'recipient_name' => 'Kofi Mensah',
        'recipient_phone' => '0241234567',
        'street_address' => 'No. 12 Test Road',
        'region' => 'Ashanti',
        'city' => 'Kumasi',
        'payment_method' => 'momo',
        'momo_name' => 'Kofi Mensah',
        'momo_phone' => '0241234567',
        'momo_network' => 'mtn',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['region']);
});

// --- Inactive delivery zone also rejected ---

test('inactive delivery zone is rejected', function () {
    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);

    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', [
        'sand_type_id' => SandType::first()->id,
        'truck_type_id' => TruckType::first()->id,
        'recipient_name' => 'Kofi Mensah',
        'recipient_phone' => '0241234567',
        'street_address' => 'No. 12 Test Road',
        'region' => 'Central',
        'city' => 'Cape Coast',
        'payment_method' => 'momo',
        'momo_name' => 'Kofi Mensah',
        'momo_phone' => '0241234567',
        'momo_network' => 'mtn',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['region']);
});

// --- Snapshot survives matrix + surcharge changes ---

test('price snapshot survives matrix and surcharge changes', function () {
    $user = User::factory()->create();
    $sand = SandType::where('name', 'Filling Sand')->first();
    $truck = TruckType::where('slug', 'small')->first();

    $response = $this->actingAs($user)->postJson('/api/v1/orders', [
        'sand_type_id' => $sand->id,
        'truck_type_id' => $truck->id,
        'recipient_name' => 'Kofi Mensah',
        'recipient_phone' => '0241234567',
        'street_address' => 'No. 12 Test Road',
        'region' => 'Central',
        'city' => 'Cape Coast',
        'payment_method' => 'cod',
    ]);

    $response->assertStatus(201);
    $orderId = $response->json('data.order.id');

    expect($response->json('data.order.price_ghs'))->toBe('900.00');
    expect($response->json('data.order.delivery_fee_ghs'))->toBe('400.00');
    expect($response->json('data.order.total_ghs'))->toBe('1300.00');

    SandTruckPrice::where('sand_type_id', $sand->id)
        ->where('truck_type_id', $truck->id)
        ->update(['price_ghs' => 5000.00]);

    DeliveryZone::where('region', 'Central')->update(['surcharge_ghs' => 9999.00]);

    $order = Order::find($orderId);
    expect($order->price_ghs)->toBe('900.00');
    expect($order->delivery_fee_ghs)->toBe('400.00');
    expect($order->total_ghs)->toBe('1300.00');
});

// --- /config returns only active regions ---

test('config returns only active delivery zone regions', function () {
    $response = $this->getJson('/api/v1/config');

    $regions = $response->json('data.regions');

    expect($regions)->toContain('Greater Accra')
        ->toContain('Central')
        ->toHaveCount(2);
});

test('config excludes inactive delivery zones', function () {
    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);

    $response = $this->getJson('/api/v1/config');

    $regions = $response->json('data.regions');
    expect($regions)->toHaveCount(1)
        ->toContain('Greater Accra')
        ->not->toContain('Central');

    $zones = $response->json('data.delivery_zones');
    expect($zones)->toHaveCount(1);
});

// --- Price matrix in config ---

test('config returns full price matrix', function () {
    $response = $this->getJson('/api/v1/config');

    $matrix = $response->json('data.price_matrix');
    expect($matrix)->toHaveCount(9);

    $firstEntry = collect($matrix)->first();
    expect($firstEntry)->toHaveKeys(['sand_type_id', 'truck_type_id', 'price_ghs']);
});

// --- Missing matrix price throws ---

test('missing matrix price throws validation exception', function () {
    $service = app(PricingService::class);
    $sand = SandType::first();
    $truck = TruckType::first();

    SandTruckPrice::where('sand_type_id', $sand->id)
        ->where('truck_type_id', $truck->id)
        ->delete();

    expect(fn () => $service->quote($sand, $truck, 'Greater Accra'))
        ->toThrow(ValidationException::class);
});
