<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

final readonly class SocialUser
{
    public function __construct(
        public string $provider,
        public string $providerId,
        public string $email,
        public string $name,
    ) {}
}
