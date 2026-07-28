<?php

declare(strict_types=1);

namespace App\Enums;

enum OrderStatus: string
{
    case Confirmed = 'confirmed';
    case OnTheWay = 'on_the_way';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Confirmed => 'Confirmed',
            self::OnTheWay => 'On The Way',
            self::Delivered => 'Delivered',
            self::Cancelled => 'Cancelled',
        };
    }

    public function progressPercent(): int
    {
        return match ($this) {
            self::Confirmed => 33,
            self::OnTheWay => 66,
            self::Delivered => 100,
            self::Cancelled => 0,
        };
    }
}
