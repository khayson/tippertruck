<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use App\Enums\SocialProvider;

/**
 * Demo tokens: base64url(payload).base64url(hmac_sha256(payload, secret))
 * payload JSON: { provider, sub, email, name, exp }
 */
final class SimulatedSocialVerifier implements SocialTokenVerifier
{
    public function __construct(private readonly string $secret) {}

    public function verify(SocialProvider $provider, string $idToken): SocialUser
    {
        $parts = explode('.', $idToken, 2);
        if (count($parts) !== 2) {
            throw new InvalidSocialTokenException('Malformed simulated token.');
        }

        [$encodedPayload, $encodedSignature] = $parts;
        $payloadJson = $this->base64UrlDecode($encodedPayload);
        $expected = $this->base64UrlEncode(
            hash_hmac('sha256', $payloadJson, $this->secret, true),
        );

        if (! hash_equals($expected, $encodedSignature)) {
            throw new InvalidSocialTokenException('Invalid simulated token signature.');
        }

        /** @var array{provider?: string, sub?: string, email?: string, name?: string, exp?: int} $payload */
        $payload = json_decode($payloadJson, true, 512, JSON_THROW_ON_ERROR);

        if (($payload['provider'] ?? null) !== $provider->value) {
            throw new InvalidSocialTokenException('Provider mismatch.');
        }

        if (! isset($payload['exp']) || (int) $payload['exp'] < time()) {
            throw new InvalidSocialTokenException('Simulated token expired.');
        }

        $sub = (string) ($payload['sub'] ?? '');
        $email = (string) ($payload['email'] ?? '');
        $name = (string) ($payload['name'] ?? '');

        if ($sub === '' || $email === '' || $name === '') {
            throw new InvalidSocialTokenException('Incomplete simulated token claims.');
        }

        return new SocialUser(
            provider: $provider->value,
            providerId: $sub,
            email: strtolower($email),
            name: $name,
        );
    }

    public static function mint(
        string $secret,
        SocialProvider $provider,
        string $sub,
        string $email,
        string $name,
        int $ttlSeconds = 3600,
    ): string {
        $payload = json_encode([
            'provider' => $provider->value,
            'sub' => $sub,
            'email' => strtolower($email),
            'name' => $name,
            'exp' => time() + $ttlSeconds,
        ], JSON_THROW_ON_ERROR);

        $encodedPayload = self::staticBase64UrlEncode($payload);
        $signature = self::staticBase64UrlEncode(
            hash_hmac('sha256', $payload, $secret, true),
        );

        return $encodedPayload.'.'.$signature;
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder > 0) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);
        if ($decoded === false) {
            throw new InvalidSocialTokenException('Invalid token encoding.');
        }

        return $decoded;
    }

    private function base64UrlEncode(string $value): string
    {
        return self::staticBase64UrlEncode($value);
    }

    private static function staticBase64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
