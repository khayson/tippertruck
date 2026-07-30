<?php

declare(strict_types=1);

namespace App\Models;

use App\Observers\DeliveryZoneObserver;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Model;

#[ObservedBy(DeliveryZoneObserver::class)]
class DeliveryZone extends Model
{
    protected $fillable = [
        'region',
        'surcharge_ghs',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'surcharge_ghs' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }
}
