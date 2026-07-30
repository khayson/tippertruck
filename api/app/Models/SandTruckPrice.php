<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SandTruckPrice extends Model
{
    protected $fillable = [
        'sand_type_id',
        'truck_type_id',
        'price_ghs',
    ];

    protected function casts(): array
    {
        return [
            'price_ghs' => 'decimal:2',
        ];
    }

    public function sandType(): BelongsTo
    {
        return $this->belongsTo(SandType::class);
    }

    public function truckType(): BelongsTo
    {
        return $this->belongsTo(TruckType::class);
    }
}
