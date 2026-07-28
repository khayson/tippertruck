<?php

declare(strict_types=1);

namespace App\Enums;

enum MomoNetwork: string
{
    case Mtn = 'mtn';
    case Telecel = 'telecel';
    case AirtelTigo = 'airteltigo';
}
