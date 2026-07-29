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
        $from = $order->status;
        $allowed = self::TRANSITIONS[$from->value] ?? [];

        if (! in_array($to->value, $allowed, true)) {
            throw ValidationException::withMessages([
                'status' => ["Cannot transition from {$from->label()} to {$to->label()}."],
            ]);
        }

        return DB::transaction(function () use ($order, $from, $to, $changedBy, $note) {
            $order->status = $to;

            match ($to) {
                OrderStatus::OnTheWay => $order->dispatched_at = now(),
                OrderStatus::Delivered => $order->delivered_at = now(),
                default => null,
            };

            $order->save();

            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => $from,
                'new_status' => $to,
                'changed_by' => $changedBy?->id,
                'note' => $note,
                'created_at' => now(),
            ]);

            return $order->fresh();
        });
    }
}
