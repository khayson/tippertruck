<?php

declare(strict_types=1);

use App\Models\SandType;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('config endpoint returns the correct shape', function () {
    $this->seed();

    $response = $this->getJson('/api/v1/config');

    $response->assertStatus(200)
        ->assertJson(['success' => true])
        ->assertJsonStructure([
            'data' => [
                'sand_types' => [['id', 'name', 'slug', 'description', 'icon', 'image_url']],
                'truck_types' => [['id', 'name', 'slug', 'capacity_label', 'price_ghs', 'is_popular']],
                'price_matrix' => [['sand_type_id', 'truck_type_id', 'price_ghs']],
                'delivery_zones' => [['region', 'surcharge_ghs']],
                'regions',
                'issue_types' => [['value', 'label']],
                'payment_networks' => [['value', 'label']],
                'social_auth' => ['mode', 'providers'],
                'config_version',
            ],
        ]);

    expect($response->json('data.sand_types'))->toHaveCount(3);
    expect($response->json('data.truck_types'))->toHaveCount(3);
    expect($response->json('data.price_matrix'))->toHaveCount(9);
    expect($response->json('data.delivery_zones'))->toHaveCount(2);
    expect($response->json('data.regions'))->toHaveCount(2);
    expect($response->json('data.issue_types'))->toHaveCount(7);
    expect($response->json('data.payment_networks'))->toHaveCount(3);
    expect($response->json('data.social_auth.providers'))->toBe(['google', 'facebook']);
});

test('config does not require authentication', function () {
    $this->seed();

    $this->getJson('/api/v1/config')->assertStatus(200);
});

test('config returns sand image_url when set', function () {
    $this->seed();

    SandType::where('slug', 'river-sand')
        ->update(['image' => 'sand-types/river.jpg']);

    $response = $this->getJson('/api/v1/config');

    $river = collect($response->json('data.sand_types'))
        ->firstWhere('slug', 'river-sand');

    expect($river['image_url'])->toContain('/storage/sand-types/river.jpg');
    expect(collect($response->json('data.sand_types'))->firstWhere('slug', 'quarry-sand')['image_url'])
        ->toBeNull();
});
