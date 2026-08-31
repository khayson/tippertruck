<?php

declare(strict_types=1);

use App\Enums\SocialProvider;
use App\Models\User;
use App\Services\SocialAuth\SimulatedSocialVerifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

beforeEach(function () {
    config([
        'social.mode' => 'simulated',
        'social.demo_secret' => 'test-social-demo-secret',
    ]);
});

function mintSimulatedToken(
    SocialProvider $provider = SocialProvider::Google,
    string $sub = 'google-sub-1',
    string $email = 'demo.google@tippertruck.test',
    string $name = 'Demo Google User',
): string {
    return SimulatedSocialVerifier::mint(
        (string) config('social.demo_secret'),
        $provider,
        $sub,
        $email,
        $name,
    );
}

test('social login creates a user and returns a token', function () {
    $token = mintSimulatedToken();

    $response = $this->postJson('/api/v1/auth/social', [
        'provider' => 'google',
        'id_token' => $token,
    ]);

    $response->assertStatus(200)
        ->assertJson([
            'success' => true,
            'errors' => null,
            'data' => [
                'user' => [
                    'email' => 'demo.google@tippertruck.test',
                    'name' => 'Demo Google User',
                    'role' => 'client',
                ],
            ],
        ])
        ->assertJsonStructure([
            'data' => ['user' => ['id', 'name', 'email', 'phone', 'role', 'created_at'], 'token'],
        ]);

    $this->assertDatabaseHas('users', [
        'email' => 'demo.google@tippertruck.test',
        'provider' => 'google',
        'provider_id' => 'google-sub-1',
    ]);

    expect(User::where('email', 'demo.google@tippertruck.test')->value('password'))->toBeNull();
});

test('social login rejects an invalid simulated signature', function () {
    $token = mintSimulatedToken().'tampered';

    $this->postJson('/api/v1/auth/social', [
        'provider' => 'google',
        'id_token' => $token,
    ])->assertStatus(401)
        ->assertJson(['success' => false]);
});

test('social login does not duplicate the same provider identity', function () {
    $token = mintSimulatedToken();

    $this->postJson('/api/v1/auth/social', [
        'provider' => 'google',
        'id_token' => $token,
    ])->assertStatus(200);

    $again = mintSimulatedToken();

    $this->postJson('/api/v1/auth/social', [
        'provider' => 'google',
        'id_token' => $again,
    ])->assertStatus(200);

    expect(User::where('email', 'demo.google@tippertruck.test')->count())->toBe(1);
});

test('social login links to an existing email password account', function () {
    $existing = User::factory()->create([
        'email' => 'linked@example.com',
        'name' => 'Existing User',
    ]);

    $token = mintSimulatedToken(
        SocialProvider::Facebook,
        'fb-sub-9',
        'linked@example.com',
        'Facebook Name',
    );

    $this->postJson('/api/v1/auth/social', [
        'provider' => 'facebook',
        'id_token' => $token,
    ])->assertStatus(200)
        ->assertJsonPath('data.user.id', $existing->id)
        ->assertJsonPath('data.user.email', 'linked@example.com');

    $existing->refresh();
    expect($existing->provider)->toBe('facebook');
    expect($existing->provider_id)->toBe('fb-sub-9');
    expect($existing->password)->not->toBeNull();
});

test('social login rejects an unknown provider', function () {
    $this->postJson('/api/v1/auth/social', [
        'provider' => 'apple',
        'id_token' => str_repeat('x', 20),
    ])->assertStatus(422)
        ->assertJsonValidationErrors(['provider']);
});

test('config includes social_auth', function () {
    $this->seed();

    $this->getJson('/api/v1/config')
        ->assertStatus(200)
        ->assertJsonPath('data.social_auth.mode', 'simulated')
        ->assertJsonPath('data.social_auth.providers', ['google', 'facebook']);
});

test('google real mode verifies via tokeninfo', function () {
    config([
        'social.mode' => 'real',
        'social.google.client_id' => 'tipper-google-client',
    ]);

    Http::fake([
        'oauth2.googleapis.com/tokeninfo*' => Http::response([
            'aud' => 'tipper-google-client',
            'sub' => 'real-google-sub',
            'email' => 'real.google@example.com',
            'name' => 'Real Google User',
        ]),
    ]);

    $this->postJson('/api/v1/auth/social', [
        'provider' => 'google',
        'id_token' => 'real-google-id-token-value',
    ])->assertStatus(200)
        ->assertJsonPath('data.user.email', 'real.google@example.com');

    $this->assertDatabaseHas('users', [
        'email' => 'real.google@example.com',
        'provider' => 'google',
        'provider_id' => 'real-google-sub',
    ]);
});
