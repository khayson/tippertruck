<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use App\Enums\SocialProvider;

interface SocialTokenVerifier
{
    /**
     * @throws InvalidSocialTokenException
     */
    public function verify(SocialProvider $provider, string $idToken): SocialUser;
}
