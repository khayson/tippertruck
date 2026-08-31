<?php

declare(strict_types=1);

use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(fn () => $this->seed());

test('login response includes flat user role for operator', function () {
    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'operator@tippertruck.test',
        'password' => 'password',
    ]);

    $response->assertStatus(200)
        ->assertJsonPath('data.user.role', 'operator')
        ->assertJsonPath('data.user.email', 'operator@tippertruck.test');

    expect($response->json('data.user'))->not->toHaveKey('data');
});

test('login response includes flat user role for admin', function () {
    $this->postJson('/api/v1/auth/login', [
        'email' => 'admin@tippertruck.test',
        'password' => 'password',
    ])->assertStatus(200)
        ->assertJsonPath('data.user.role', 'admin');
});
