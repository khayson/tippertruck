<?php

declare(strict_types=1);

use App\Enums\OrderStatus;
use App\Models\ChatbotUnmatchedLog;
use App\Models\Order;
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

// ─── Corpus-driven test ─────────────────────────────────────────────

$corpus = require __DIR__.'/../../Fixtures/chatbot_corpus.php';

foreach ($corpus as $i => $entry) {
    $label = "corpus #{$i}: \"{$entry['input']}\" → {$entry['intent']}";

    test($label, function () use ($entry) {
        $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
            'message' => $entry['input'],
        ]);

        $response->assertStatus(200);
        expect($response->json('data.matched_rule'))->toBe($entry['intent']);

        if (isset($entry['suggested_issue_type'])) {
            expect($response->json('data.suggested_issue_type'))->toBe($entry['suggested_issue_type']);
        }
    });
}

// ─── Response shape ─────────────────────────────────────────────────

test('response has correct shape with new fields', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'Hello',
    ]);

    $response->assertJsonStructure([
        'success',
        'data' => [
            'reply',
            'matched_rule',
            'confidence',
            'entities',
            'quick_replies',
            'unmatched_count',
            'suggested_issue_type',
        ],
    ]);

    expect($response->json('data.confidence'))->toBeFloat();
    expect($response->json('data.unmatched_count'))->toBeInt();
    expect($response->json('data.suggested_issue_type'))->toBeNull();
});

// ─── Entity-scoped answers ──────────────────────────────────────────

test('pricing reply for specific truck entity', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'how much is the medium truck',
    ]);

    $response->assertStatus(200);
    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('pricing');
    expect($data['entities'])->toHaveKey('truck_type');
    expect($data['entities']['truck_type']['name'])->toBe('Medium Truck');
    expect($data['reply'])->toContain('GHS 450.00');
    expect($data['reply'])->not->toContain('Small Truck');
});

test('sand types reply for specific sand entity', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'tell me about river sand',
    ]);

    $response->assertStatus(200);
    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('sand_types');
    expect($data['entities'])->toHaveKey('sand_type');
    expect($data['entities']['sand_type']['name'])->toBe('River Sand');
    expect($data['reply'])->not->toContain('Quarry Sand');
});

test('truck sizes reply for specific truck entity', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'how big is the large truck',
    ]);

    $response->assertStatus(200);
    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('truck_sizes');
    expect($data['entities'])->toHaveKey('truck_type');
    expect($data['entities']['truck_type']['name'])->toBe('Large Truck');
    expect($data['reply'])->not->toContain('Small Truck');
});

// ─── Complaint routing ─────────────────────────────────────────────

test('complaint about late delivery returns suggested_issue_type', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'my delivery is late and has been delayed',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('report_issue');
    expect($data['suggested_issue_type'])->toBe('late_delivery');
});

test('complaint about payment returns suggested_issue_type', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'i paid but nothing happened',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('report_issue');
    expect($data['suggested_issue_type'])->toBe('payment_issue');
});

test('complaint quick_replies include issue_type for prefill', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'the driver was rude to me',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('report_issue');
    expect($data['suggested_issue_type'])->toBe('driver_conduct');

    $firstReply = $data['quick_replies'][0];
    expect($firstReply['issue_type'])->toBe('driver_conduct');
});

test('general report_issue has null suggested_issue_type', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'i want to report an issue',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('report_issue');
    expect($data['suggested_issue_type'])->toBeNull();
});

// ─── Order status ───────────────────────────────────────────────────

test('order_status with active order returns order details', function () {
    $order = Order::factory()->create([
        'user_id' => $this->user->id,
        'status' => OrderStatus::Confirmed,
    ]);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'where is my order',
    ]);

    $response->assertStatus(200);
    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('order_status');
    expect($data['reply'])->toContain($order->order_ref);
    expect($data['reply'])->toContain('Confirmed');
    expect($data['reply'])->toContain('33%');
});

test('order_status with no active orders offers to book', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'where is my order',
    ]);

    $response->assertStatus(200);
    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('order_status');
    expect($data['reply'])->toContain('no active orders');
});

test('order_status with multiple active orders reports count', function () {
    Order::factory()->create([
        'user_id' => $this->user->id,
        'status' => OrderStatus::Confirmed,
        'created_at' => now()->subHour(),
    ]);
    $latest = Order::factory()->create([
        'user_id' => $this->user->id,
        'status' => OrderStatus::OnTheWay,
        'created_at' => now(),
    ]);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'check my delivery status',
    ]);

    $data = $response->json('data');
    expect($data['reply'])->toContain($latest->order_ref);
    expect($data['reply'])->toContain('1 other active order');
});

test('order_status ignores terminal orders', function () {
    Order::factory()->create([
        'user_id' => $this->user->id,
        'status' => OrderStatus::Delivered,
    ]);
    Order::factory()->create([
        'user_id' => $this->user->id,
        'status' => OrderStatus::Cancelled,
    ]);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'where is my order',
    ]);

    expect($response->json('data.reply'))->toContain('no active orders');
});

// ─── Order cancellation ────────────────────────────────────────────

test('order_cancellation explains cancel process', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'how do i cancel my order',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('order_cancellation');
    expect($data['reply'])->toContain('Confirmed');
    expect($data['reply'])->toContain('report an issue');
});

// ─── Delivery coverage ─────────────────────────────────────────────

test('delivery_coverage lists regions', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'which regions do you deliver to',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('delivery_coverage');
    expect($data['reply'])->toContain('Greater Accra');
    expect($data['reply'])->toContain('Ashanti');
});

test('delivery_coverage resolves city to region', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'do you deliver to kumasi',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('delivery_coverage');
    expect($data['reply'])->toContain('Kumasi');
    expect($data['reply'])->toContain('Ashanti');
});

// ─── Human handoff ──────────────────────────────────────────────────

test('human_handoff routes to issue reporting', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'can i speak to someone please',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('human_handoff');
    expect($data['reply'])->toContain('report');

    $labels = array_column($data['quick_replies'], 'label');
    expect($labels)->toContain('Report issue');
});

// ─── Confidence and uncertainty ─────────────────────────────────────

test('confidence below threshold triggers fallback', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'xyzzy foobar gibberish',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('fallback');
    expect($data['confidence'])->toBeLessThan(0.30);
});

test('confident match returns high confidence', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'what are your prices',
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('pricing');
    expect($data['confidence'])->toBeGreaterThanOrEqual(0.30);
});

// ─── Escalation ─────────────────────────────────────────────────────

test('escalation at unmatched_count 2 adds report issue quick reply', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'xyzzy gibberish',
        'unmatched_count' => 2,
    ]);

    $data = $response->json('data');
    expect($data['matched_rule'])->toBe('fallback');
    expect($data['unmatched_count'])->toBe(3);

    $labels = array_column($data['quick_replies'], 'label');
    expect($labels)->toContain('Report an issue');
});

test('unmatched_count increments on fallback', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'xyzzy gibberish',
        'unmatched_count' => 0,
    ]);

    expect($response->json('data.unmatched_count'))->toBe(1);
});

test('unmatched_count stays same on match', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'what are your prices',
        'unmatched_count' => 2,
    ]);

    expect($response->json('data.unmatched_count'))->toBe(2);
});

// ─── Logging ────────────────────────────────────────────────────────

test('fallback logs to chatbot_unmatched_logs', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'random gibberish xyz',
    ]);

    $log = ChatbotUnmatchedLog::first();
    expect($log)->not->toBeNull();
    expect($log->user_id)->toBe($this->user->id);
    expect($log->message)->toBe('random gibberish xyz');
});

test('successful match does not log to unmatched', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'what are your prices',
    ]);

    expect(ChatbotUnmatchedLog::count())->toBe(0);
});

// ─── Live price interpolation ───────────────────────────────────────

test('pricing reply reflects updated truck price', function () {
    $truck = TruckType::where('slug', 'medium')->first();
    $truck->update(['price_ghs' => 999.50]);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'what are your prices',
    ]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('GHS 999.50');
    expect($reply)->not->toContain('GHS 450.00');
});

test('sand types reply reflects updated sand name', function () {
    $sand = SandType::where('slug', 'river-sand')->first();
    $sand->update(['name' => 'Premium River Sand']);

    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'what sand types do you have',
    ]);

    $reply = $response->json('data.reply');
    expect($reply)->toContain('Premium River Sand');
});

// ─── Word boundary matching ─────────────────────────────────────────

test('hi does not match this or history', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'this is just history',
    ]);

    expect($response->json('data.matched_rule'))->not->toBe('greeting');
});

// ─── Deterministic scoring ──────────────────────────────────────────

test('specific rule wins over generic when both could match', function () {
    $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
        'message' => 'how much does a truck cost',
    ]);

    expect($response->json('data.matched_rule'))->toBe('pricing');
});

// ─── Auth ───────────────────────────────────────────────────────────

test('unauthenticated user cannot use chatbot', function () {
    $this->postJson('/api/v1/chatbot/message', [
        'message' => 'Hello',
    ])->assertStatus(401);
});

// ─── Validation ─────────────────────────────────────────────────────

test('message is required', function () {
    $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [])
        ->assertStatus(422)
        ->assertJsonValidationErrors(['message']);
});
