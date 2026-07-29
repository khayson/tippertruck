<?php

declare(strict_types=1);

use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Database\Seeders\SandTypeSeeder;
use Database\Seeders\TruckTypeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed([SandTypeSeeder::class, TruckTypeSeeder::class]);
    $this->user = User::factory()->create();
});

// --- Rule matching ---

test('greeting rule matches hello', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'Hello there!',
    ]);

    $response->assertStatus(200)
        ->assertJson([
            'success' => true,
            'data' => ['matched_rule' => 'greeting'],
        ]);
});

test('pricing rule matches and returns live prices', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What are your prices?',
    ]);

    $response->assertStatus(200)
        ->assertJson(['data' => ['matched_rule' => 'pricing']]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('GHS 250.00');
    expect($reply)->toContain('GHS 450.00');
    expect($reply)->toContain('GHS 700.00');
});

test('sand_types rule matches', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What sand types do you have?',
    ]);

    $response->assertStatus(200)
        ->assertJson(['data' => ['matched_rule' => 'sand_types']]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('River Sand');
    expect($reply)->toContain('Quarry Sand');
    expect($reply)->toContain('Filling Sand');
});

test('truck_sizes rule matches', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What truck sizes are available?',
    ]);

    $response->assertStatus(200)
        ->assertJson(['data' => ['matched_rule' => 'truck_sizes']]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('Small Truck');
    expect($reply)->toContain('Medium Truck');
    expect($reply)->toContain('Large Truck');
});

test('how_to_book rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How do I place an order?',
    ])->assertJson(['data' => ['matched_rule' => 'how_to_book']]);
});

test('payment_methods rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What payment methods do you accept?',
    ])->assertJson(['data' => ['matched_rule' => 'payment_methods']]);
});

test('momo_help rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How does mobile money work?',
    ])->assertJson(['data' => ['matched_rule' => 'momo_help']]);
});

test('cash_on_delivery rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How does cash on delivery work?',
    ])->assertJson(['data' => ['matched_rule' => 'cash_on_delivery']]);
});

test('tracking rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How do I track my order?',
    ])->assertJson(['data' => ['matched_rule' => 'tracking']]);
});

test('delivery_time rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How long does delivery take?',
    ])->assertJson(['data' => ['matched_rule' => 'delivery_time']]);
});

test('order_history rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'Where can I see my past orders?',
    ])->assertJson(['data' => ['matched_rule' => 'order_history']]);
});

test('report_issue rule matches', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'I want to report a problem',
    ])->assertJson(['data' => ['matched_rule' => 'report_issue']]);
});

// --- Fallback ---

test('unmatched input returns fallback with quick_replies', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'xyzzy foobar gibberish',
    ]);

    $response->assertStatus(200)
        ->assertJson(['data' => ['matched_rule' => 'fallback']]);

    $quickReplies = $response->json('data.quick_replies');
    expect(count($quickReplies))->toBeGreaterThanOrEqual(4);
});

// --- Live price interpolation ---

test('pricing reply reflects updated truck price', function () {
    $truck = TruckType::where('slug', 'medium')->first();
    $truck->update(['price_ghs' => 999.50]);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What are your prices?',
    ]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('GHS 999.50');
    expect($reply)->not->toContain('GHS 450.00');
});

test('sand types reply reflects updated sand name', function () {
    $sand = SandType::where('slug', 'river-sand')->first();
    $sand->update(['name' => 'Premium River Sand']);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'What sand types do you have?',
    ]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('Premium River Sand');
    expect($reply)->not->toContain("\nRiver Sand");
});

// --- Deterministic matching: more specific wins ---

test('specific rule wins over generic when both could match', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'How much does a truck cost?',
    ]);

    expect($response->json('data.matched_rule'))->toBe('pricing');
});

test('cash on delivery matches before report_issue for cod keyword', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'Tell me about cod payments',
    ]);

    expect($response->json('data.matched_rule'))->toBe('cash_on_delivery');
});

// --- Response shape ---

test('chatbot response has correct shape', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'Hello',
    ]);

    $response->assertJsonStructure([
        'success',
        'data' => [
            'reply',
            'matched_rule',
            'quick_replies' => [['label', 'message']],
        ],
    ]);
});

// --- Auth ---

test('unauthenticated user cannot use chatbot', function () {
    $this->postJson('/api/v1/chatbot/message', [
        'message' => 'Hello',
    ])->assertStatus(401);
});

// --- Validation ---

test('message is required', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['message']);
});
