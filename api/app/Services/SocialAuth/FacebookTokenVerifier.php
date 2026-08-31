<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use App\Enums\SocialProvider;
use Illuminate\Support\Facades\Http;

final class FacebookTokenVerifier implements SocialTokenVerifier
{
    public function __construct(
        private readonly string $appId,
        private readonly string $appSecret,
    ) {}

    public function verify(SocialProvider $provider, string $idToken): SocialUser
    {
        if ($provider !== SocialProvider::Facebook) {
            throw new InvalidSocialTokenException('Facebook verifier received the wrong provider.');
        }

        $appToken = $this->appId.'|'.$this->appSecret;

        $debug = Http::timeout(10)->get('https://graph.facebook.com/debug_token', [
            'input_token' => $idToken,
            'access_token' => $appToken,
        ]);

        if (! $debug->successful() || ! ($debug->json('data.is_valid') ?? false)) {
            throw new InvalidSocialTokenException('Facebook token verification failed.');
        }

        if ((string) $debug->json('data.app_id') !== $this->appId) {
            throw new InvalidSocialTokenException('Facebook token app mismatch.');
        }

        $me = Http::timeout(10)->get('https://graph.facebook.com/me', [
            'fields' => 'id,name,email',
            'access_token' => $idToken,
        ]);

        if (! $me->successful()) {
            throw new InvalidSocialTokenException('Facebook profile lookup failed.');
        }

        $sub = (string) $me->json('id', '');
        $email = strtolower((string) $me->json('email', ''));
        $name = (string) ($me->json('name') ?: $email);

        if ($sub === '' || $email === '') {
            throw new InvalidSocialTokenException('Facebook token missing required claims.');
        }

        return new SocialUser(
            provider: SocialProvider::Facebook->value,
            providerId: $sub,
            email: $email,
            name: $name,
        );
    }
}
