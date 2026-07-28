<?php

declare(strict_types=1);

use App\Models\User;
use App\Services\AuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;

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

test('login is throttled after 5 attempts and returns Retry-After', function () {
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
        ->assertJson(['success' => false])
        ->assertHeader('Retry-After');
});

test('two different emails from the same IP do not share a throttle bucket', function () {
    User::factory()->create(['email' => 'a@example.com', 'password' => 'Secret1234']);
    User::factory()->create(['email' => 'b@example.com', 'password' => 'Secret1234']);

    for ($i = 0; $i < 5; $i++) {
        $this->postJson('/api/v1/auth/login', [
            'email' => 'a@example.com',
            'password' => 'Wrong'.$i.'Pass',
        ]);
    }

    $response = $this->postJson('/api/v1/auth/login', [
        'email' => 'b@example.com',
        'password' => 'Secret1234',
    ]);

    $response->assertStatus(200);
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

test('logout revokes only the current token', function () {
    $user = User::factory()->create([
        'email' => 'logout@example.com',
        'password' => 'Secret1234',
    ]);

    $loginA = $this->postJson('/api/v1/auth/login', [
        'email' => 'logout@example.com',
        'password' => 'Secret1234',
    ]);
    $tokenA = $loginA->json('data.token');

    $loginB = $this->postJson('/api/v1/auth/login', [
        'email' => 'logout@example.com',
        'password' => 'Secret1234',
    ]);
    $tokenB = $loginB->json('data.token');

    $this->withHeaders(['Authorization' => "Bearer $tokenA"])
        ->postJson('/api/v1/auth/logout')
        ->assertStatus(200)
        ->assertJson(['success' => true, 'message' => 'Logged out.']);

    app('auth')->forgetGuards();

    $this->withHeaders(['Authorization' => "Bearer $tokenA"])
        ->getJson('/api/v1/auth/me')
        ->assertStatus(401);

    app('auth')->forgetGuards();

    $this->withHeaders(['Authorization' => "Bearer $tokenB"])
        ->getJson('/api/v1/auth/me')
        ->assertStatus(200);
});

test('404 returns envelope shape', function () {
    $response = $this->getJson('/api/v1/does-not-exist');

    $response->assertStatus(404)
        ->assertExactJson([
            'success' => false,
            'message' => 'Not found.',
            'data' => null,
            'errors' => null,
        ]);
});

test('500 returns envelope shape with generic message when debug off', function () {
    config(['app.debug' => false]);

    Route::get('api/v1/test-500', fn () => throw new RuntimeException('Kaboom'));

    $response = $this->getJson('/api/v1/test-500');

    $response->assertStatus(500)
        ->assertExactJson([
            'success' => false,
            'message' => 'Server error.',
            'data' => null,
            'errors' => null,
        ]);
});

test('DUMMY_HASH is a valid 60-char bcrypt hash that rejects all passwords', function () {
    $hash = AuthService::DUMMY_HASH;

    expect(strlen($hash))->toBe(60);
    expect(password_get_info($hash)['algoName'])->toBe('bcrypt');
    expect(Hash::check('anything', $hash))->toBeFalse();
});
