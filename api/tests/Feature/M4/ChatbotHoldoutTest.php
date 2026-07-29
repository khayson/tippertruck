<?php

declare(strict_types=1);

use App\Models\User;
use Database\Seeders\SandTypeSeeder;
use Database\Seeders\TruckTypeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed([SandTypeSeeder::class, TruckTypeSeeder::class]);
    $this->user = User::factory()->create();
});

$holdout = require __DIR__.'/../../Fixtures/chatbot_holdout.php';

foreach ($holdout as $i => $entry) {
    $label = "holdout #{$i}: \"{$entry['input']}\" → {$entry['intent']}";

    test($label, function () use ($entry) {
        $response = $this->actingAs($this->user)->postJson('/api/v1/chatbot/message', [
            'message' => $entry['input'],
        ]);

        $response->assertStatus(200);
        expect($response->json('data.matched_rule'))->toBe($entry['intent']);
    });
}
