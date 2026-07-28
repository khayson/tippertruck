<?php

declare(strict_types=1);

namespace App\Enums;

enum UserRole: string
{
    case Client = 'client';
    case Operator = 'operator';
    case Admin = 'admin';
}
