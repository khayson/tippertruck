<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Enums\OrderStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<OrderStatusLog> */
class OrderStatusLogFactory extends Factory
{
    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'old_status' => null,
            'new_status' => OrderStatus::Confirmed,
            'changed_by' => null,
            'note' => null,
            'created_at' => now(),
        ];
    }
}
