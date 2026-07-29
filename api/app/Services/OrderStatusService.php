<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderStatusService
{
    private const TRANSITIONS = [
        'confirmed' => ['on_the_way', 'cancelled'],
        'on_the_way' => ['delivered', 'cancelled'],
        'delivered' => [],
        'cancelled' => [],
    ];

    public function transition(Order $order, OrderStatus $to, ?User $changedBy = null, ?string $note = null): Order
    {
        return DB::transaction(function () use ($order, $to, $changedBy, $note) {
            $locked = Order::lockForUpdate()->findOrFail($order->id);
            $from = $locked->status;

            $allowed = self::TRANSITIONS[$from->value] ?? [];

            if (! in_array($to->value, $allowed, true)) {
                throw ValidationException::withMessages([
                    'status' => ["Cannot transition from {$from->label()} to {$to->label()}."],
                ]);
            }

            $locked->status = $to;

            match ($to) {
                OrderStatus::OnTheWay => $locked->dispatched_at = now(),
                OrderStatus::Delivered => $locked->delivered_at = now(),
                default => null,
            };

            $locked->save();

            OrderStatusLog::create([
                'order_id' => $locked->id,
                'old_status' => $from,
                'new_status' => $to,
                'changed_by' => $changedBy?->id,
                'note' => $note,
                'created_at' => now(),
            ]);

            return $locked->fresh();
        });
    }
}
