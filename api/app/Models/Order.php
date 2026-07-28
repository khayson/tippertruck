<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\MomoNetwork;
use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use Database\Factories\OrderFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    /** @use HasFactory<OrderFactory> */
    use HasFactory;

    protected $fillable = [
        'order_ref',
        'user_id',
        'sand_type_id',
        'truck_type_id',
        'price_ghs',
        'delivery_fee_ghs',
        'total_ghs',
        'recipient_name',
        'recipient_phone',
        'street_address',
        'region',
        'city',
        'landmark',
        'delivery_note',
        'payment_method',
        'payment_status',
        'momo_name',
        'momo_phone',
        'momo_network',
        'status',
        'assigned_operator_id',
        'confirmed_at',
        'dispatched_at',
        'delivered_at',
    ];

    protected function casts(): array
    {
        return [
            'price_ghs' => 'decimal:2',
            'delivery_fee_ghs' => 'decimal:2',
            'total_ghs' => 'decimal:2',
            'payment_method' => PaymentMethod::class,
            'payment_status' => PaymentStatus::class,
            'momo_network' => MomoNetwork::class,
            'status' => OrderStatus::class,
            'confirmed_at' => 'datetime',
            'dispatched_at' => 'datetime',
            'delivered_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sandType(): BelongsTo
    {
        return $this->belongsTo(SandType::class);
    }

    public function truckType(): BelongsTo
    {
        return $this->belongsTo(TruckType::class);
    }

    public function assignedOperator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_operator_id');
    }

    public function statusLogs(): HasMany
    {
        return $this->hasMany(OrderStatusLog::class);
    }

    public function issues(): HasMany
    {
        return $this->hasMany(Issue::class);
    }
}
