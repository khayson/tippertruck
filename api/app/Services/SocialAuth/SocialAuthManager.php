<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use App\Enums\SocialProvider;

final class SocialAuthManager
{
    public function effectiveMode(?SocialProvider $provider = null): string
    {
        $mode = (string) config('social.mode', 'auto');

        if ($mode === 'simulated' || $mode === 'real') {
            return $mode;
        }

        // auto
        if ($provider === null) {
            $anyReal = $this->hasGoogleCredentials() || $this->hasFacebookCredentials();

            return $anyReal ? 'real' : 'simulated';
        }

        return $this->hasCredentialsFor($provider) ? 'real' : 'simulated';
    }

    public function configPayload(): array
    {
        $providers = config('social.providers', ['google', 'facebook']);

        // Client uses a single mode for UI; prefer simulated unless every
        // listed provider can do real verification under auto/real.
        $mode = (string) config('social.mode', 'auto');
        if ($mode === 'auto') {
            $allReal = collect($providers)->every(
                fn (string $p) => $this->hasCredentialsFor(SocialProvider::from($p)),
            );
            $mode = $allReal ? 'real' : 'simulated';
        }

        return [
            'mode' => $mode,
            'providers' => $providers,
        ];
    }

    public function verifierFor(SocialProvider $provider): SocialTokenVerifier
    {
        $mode = $this->effectiveMode($provider);

        if ($mode === 'simulated') {
            return new SimulatedSocialVerifier((string) config('social.demo_secret'));
        }

        return match ($provider) {
            SocialProvider::Google => new GoogleTokenVerifier(
                (string) config('social.google.client_id'),
            ),
            SocialProvider::Facebook => new FacebookTokenVerifier(
                (string) config('social.facebook.app_id'),
                (string) config('social.facebook.app_secret'),
            ),
        };
    }

    public function verify(SocialProvider $provider, string $idToken): SocialUser
    {
        return $this->verifierFor($provider)->verify($provider, $idToken);
    }

    private function hasCredentialsFor(SocialProvider $provider): bool
    {
        return match ($provider) {
            SocialProvider::Google => $this->hasGoogleCredentials(),
            SocialProvider::Facebook => $this->hasFacebookCredentials(),
        };
    }

    private function hasGoogleCredentials(): bool
    {
        return filled(config('social.google.client_id'));
    }

    private function hasFacebookCredentials(): bool
    {
        return filled(config('social.facebook.app_id'))
            && filled(config('social.facebook.app_secret'));
    }
}
