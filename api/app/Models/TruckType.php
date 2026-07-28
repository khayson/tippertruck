<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TruckTypeFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TruckType extends Model
{
    /** @use HasFactory<TruckTypeFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'capacity_label',
        'capacity_tonnes_min',
        'capacity_tonnes_max',
        'price_ghs',
        'is_popular',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'capacity_tonnes_min' => 'decimal:1',
            'capacity_tonnes_max' => 'decimal:1',
            'price_ghs' => 'decimal:2',
            'is_popular' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
