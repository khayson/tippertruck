<?php

declare(strict_types=1);

use App\Enums\IssueStatus;
use App\Models\Issue;
use App\Models\Order;
use App\Models\User;
use Database\Seeders\SandTypeSeeder;
use Database\Seeders\TruckTypeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed([SandTypeSeeder::class, TruckTypeSeeder::class]);
});

// --- Creation ---

test('user can create an issue', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'late_delivery',
        'description' => 'My delivery was over two hours late and I had workers waiting.',
    ]);

    $response->assertStatus(201)
        ->assertJson([
            'success' => true,
            'data' => [
                'issue' => [
                    'issue_type' => 'late_delivery',
                    'status' => 'open',
                    'admin_response' => null,
                    'order_ref' => null,
                ],
            ],
        ]);
});

test('user can create an issue linked to their own order', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id]);

    $response = $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'wrong_quantity',
        'description' => 'The truck delivered less sand than expected for the order.',
        'order_id' => $order->id,
    ]);

    $response->assertStatus(201)
        ->assertJson([
            'data' => [
                'issue' => [
                    'order_ref' => $order->order_ref,
                ],
            ],
        ]);
});

test('another user order_id is rejected as validation error', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $otherOrder = Order::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'payment_issue',
        'description' => 'I was charged twice for the same delivery order.',
        'order_id' => $otherOrder->id,
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['order_id']);
});

test('issue_type must be valid enum', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'invalid_type',
        'description' => 'Some description that is long enough.',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['issue_type']);
});

test('description minimum 10 characters', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'other',
        'description' => 'Too short',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['description']);
});

test('issue defaults to open status', function () {
    $user = User::factory()->create();

    $this->actingAs($user)->postJson('/api/v1/issues', [
        'issue_type' => 'driver_conduct',
        'description' => 'The driver was rude and unprofessional during delivery.',
    ])->assertStatus(201);

    $issue = Issue::first();
    expect($issue->status)->toBe(IssueStatus::Open);
});

// --- List ---

test('issues list returns only current user issues', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();
    Issue::factory()->count(3)->create(['user_id' => $userA->id]);
    Issue::factory()->count(2)->create(['user_id' => $userB->id]);

    $response = $this->actingAs($userA)->getJson('/api/v1/issues');

    $response->assertStatus(200)
        ->assertJsonCount(3, 'data.issues')
        ->assertJsonStructure([
            'data' => [
                'issues' => [['id', 'issue_type', 'description', 'status', 'admin_response', 'order_ref', 'created_at']],
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ],
        ]);
});

test('issues list returns newest first', function () {
    $user = User::factory()->create();
    $old = Issue::factory()->create(['user_id' => $user->id, 'created_at' => now()->subDay()]);
    $new = Issue::factory()->create(['user_id' => $user->id, 'created_at' => now()]);

    $response = $this->actingAs($user)->getJson('/api/v1/issues');

    $ids = collect($response->json('data.issues'))->pluck('id');
    expect($ids->first())->toBe($new->id);
    expect($ids->last())->toBe($old->id);
});

test('issues list includes order_ref when linked', function () {
    $user = User::factory()->create();
    $order = Order::factory()->create(['user_id' => $user->id]);
    Issue::factory()->create(['user_id' => $user->id, 'order_id' => $order->id]);

    $response = $this->actingAs($user)->getJson('/api/v1/issues');

    expect($response->json('data.issues.0.order_ref'))->toBe($order->order_ref);
});

// --- Auth ---

test('unauthenticated user cannot create issue', function () {
    $this->postJson('/api/v1/issues', [
        'issue_type' => 'other',
        'description' => 'Some issue description here.',
    ])->assertStatus(401);
});

test('unauthenticated user cannot list issues', function () {
    $this->getJson('/api/v1/issues')->assertStatus(401);
});
