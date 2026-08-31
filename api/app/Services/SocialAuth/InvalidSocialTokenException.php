<?php

declare(strict_types=1);

namespace App\Services\SocialAuth;

use Exception;

class InvalidSocialTokenException extends Exception
{
    public function __construct(string $message = 'Invalid social token.')
    {
        parent::__construct($message);
    }
}
