<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class OrderService
{
    public function create(array $data, User $user): Order
    {
        $truckType = TruckType::findOrFail($data['truck_type_id']);
        $price = $truckType->price_ghs;

        return DB::transaction(function () use ($data, $user, $price) {
            $order = Order::create([
                'order_ref' => $this->generateOrderRef(),
                'user_id' => $user->id,
                'sand_type_id' => $data['sand_type_id'],
                'truck_type_id' => $data['truck_type_id'],
                'price_ghs' => $price,
                'delivery_fee_ghs' => 0,
                'total_ghs' => $price,
                'recipient_name' => $data['recipient_name'],
                'recipient_phone' => $data['recipient_phone'],
                'street_address' => $data['street_address'],
                'region' => $data['region'],
                'city' => $data['city'],
                'landmark' => $data['landmark'] ?? null,
                'delivery_note' => $data['delivery_note'] ?? null,
                'payment_method' => $data['payment_method'],
                'momo_name' => $data['momo_name'] ?? null,
                'momo_phone' => $data['momo_phone'] ?? null,
                'momo_network' => $data['momo_network'] ?? null,
                'status' => OrderStatus::Confirmed,
                'payment_status' => PaymentStatus::Pending,
                'confirmed_at' => now(),
            ]);

            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => null,
                'new_status' => OrderStatus::Confirmed,
                'changed_by' => $user->id,
                'note' => 'Order placed',
                'created_at' => now(),
            ]);

            return $order->load(['sandType', 'truckType', 'statusLogs']);
        });
    }

    private function generateOrderRef(): string
    {
        $date = now()->format('Ymd');
        $prefix = "TT-{$date}-";

        $lastSeq = Order::where('order_ref', 'like', "{$prefix}%")
            ->selectRaw('MAX(CAST(SUBSTRING(order_ref, -4) AS UNSIGNED)) as max_seq')
            ->value('max_seq') ?? 0;

        return $prefix.str_pad((string) ($lastSeq + 1), 4, '0', STR_PAD_LEFT);
    }
}
