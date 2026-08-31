<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use App\Enums\SocialProvider;
use Illuminate\Support\Facades\Http;

final class GoogleTokenVerifier implements SocialTokenVerifier
{
    public function __construct(private readonly string $clientId) {}

    public function verify(SocialProvider $provider, string $idToken): SocialUser
    {
        if ($provider !== SocialProvider::Google) {
            throw new InvalidSocialTokenException('Google verifier received the wrong provider.');
        }

        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (! $response->successful()) {
            throw new InvalidSocialTokenException('Google token verification failed.');
        }

        $aud = (string) $response->json('aud', '');
        if ($aud !== $this->clientId) {
            throw new InvalidSocialTokenException('Google token audience mismatch.');
        }

        $sub = (string) $response->json('sub', '');
        $email = strtolower((string) $response->json('email', ''));
        $name = (string) ($response->json('name') ?: $email);

        if ($sub === '' || $email === '') {
            throw new InvalidSocialTokenException('Google token missing required claims.');
        }

        return new SocialUser(
            provider: SocialProvider::Google->value,
            providerId: $sub,
            email: $email,
            name: $name,
        );
    }
}
