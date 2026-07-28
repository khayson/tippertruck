<?php

declare(strict_types=1);

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('register creates a user and returns token', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Ama Serwaa',
        'email' => 'ama@example.com',
        'password' => 'Secret1234',
        'password_confirmation' => 'Secret1234',
        'phone' => '0241234567',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => ['user' => ['id', 'name', 'email', 'phone', 'role', 'created_at'], 'token'],
            'errors',
        ])
        ->assertJson([
            'success' => true,
            'errors' => null,
            'data' => [
                'user' => [
                    'name' => 'Ama Serwaa',
                    'email' => 'ama@example.com',
                    'phone' => '0241234567',
                    'role' => 'client',
                ],
            ],
        ]);

    expect($response->json('data.user'))->not->toHaveKeys(['password', 'remember_token']);
    expect(User::where('email', 'ama@example.com')->exists())->toBeTrue();
});

test('register rejects duplicate email', function () {
    User::factory()->create(['email' => 'taken@example.com']);

    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => 'taken@example.com',
        'password' => 'Secret1234',
        'password_confirmation' => 'Secret1234',
    ]);

    $response->assertStatus(422)
        ->assertJson([
            'success' => false,
            'data' => null,
        ])
        ->assertJsonValidationErrors(['email']);
});

test('register rejects weak password', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => 'new@example.com',
        'password' => 'weak',
        'password_confirmation' => 'weak',
    ]);

    $response->assertStatus(422)
        ->assertJson(['success' => false])
        ->assertJsonValidationErrors(['password']);
});

test('register rejects password without mixed case', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => 'new@example.com',
        'password' => 'alllowercase1',
        'password_confirmation' => 'alllowercase1',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['password']);
});

test('register rejects password without number', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'name' => 'Test User',
        'email' => 'new@example.com',
        'password' => 'NoNumberHere',
        'password_confirmation' => 'NoNumberHere',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['password']);
});

test('login succeeds with correct credentials', function () {
    User::factory()->create([
        'email' => 'user@example.com',
        'password' => 'Secret1234',
    ]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'user@example.com',
        'password' => 'Secret1234',
    ]);

    $response->assertStatus(200)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => ['user' => ['id', 'name', 'email', 'phone', 'role', 'created_at'], 'token'],
            'errors',
        ])
        ->assertJson([
            'success' => true,
            'errors' => null,
        ]);
});

test('login returns 401 in envelope shape for wrong password', function () {
    User::factory()->create([
        'email' => 'user@example.com',
        'password' => 'Secret1234',
    ]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'user@example.com',
        'password' => 'WrongPassword1',
    ]);

    $response->assertStatus(401)
        ->assertExactJson([
            'success' => false,
            'message' => 'Invalid credentials.',
            'data' => null,
            'errors' => null,
        ]);
});

test('login is throttled after 5 attempts', function () {
    User::factory()->create([
        'email' => 'user@example.com',
        'password' => 'Secret1234',
    ]);

    for ($i = 0; $i < 5; $i++) {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'user@example.com',
            'password' => 'Wrong'.$i.'Pass',
        ]);
    }

    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'user@example.com',
        'password' => 'Wrong5Pass',
    ]);

    $response->assertStatus(429)
        ->assertJson(['success' => false]);
});

test('me returns the authenticated user', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->getJson('/api/v1/auth/me');

    $response->assertStatus(200)
        ->assertJson([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                ],
            ],
        ]);
});

test('me without token returns 401 in envelope', function () {
    $response = $this->getJson('/api/v1/auth/me');

    $response->assertStatus(401)
        ->assertExactJson([
            'success' => false,
            'message' => 'Unauthenticated.',
            'data' => null,
            'errors' => null,
        ]);
});

test('logout revokes the current token', function () {
    $user = User::factory()->create([
        'email' => 'logout@example.com',
        'password' => 'Secret1234',
    ]);

    $loginResponse = $this->postJson('/api/v1/auth/login', [
        'email' => 'logout@example.com',
        'password' => 'Secret1234',
    ]);
    $token = $loginResponse->json('data.token');

    $this->withHeaders(['Authorization' => "Bearer $token"])
        ->postJson('/api/v1/auth/logout')
        ->assertStatus(200)
        ->assertJson([
            'success' => true,
            'message' => 'Logged out.',
        ]);

    app('auth')->forgetGuards();

    $this->withHeaders(['Authorization' => "Bearer $token"])
        ->getJson('/api/v1/auth/me')
        ->assertStatus(401);
});
