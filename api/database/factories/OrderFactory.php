<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Order> */
class OrderFactory extends Factory
{
    public function definition(): array
    {
        $price = fake()->randomFloat(2, 200, 800);

        return [
            'order_ref' => 'TT-'.now()->format('Ymd').'-'.str_pad((string) fake()->unique()->numberBetween(1, 9999), 4, '0', STR_PAD_LEFT),
            'user_id' => User::factory(),
            'sand_type_id' => SandType::factory(),
            'truck_type_id' => TruckType::factory(),
            'price_ghs' => $price,
            'delivery_fee_ghs' => 0,
            'total_ghs' => $price,
            'recipient_name' => fake()->name(),
            'recipient_phone' => '0'.fake()->numerify('#########'),
            'street_address' => fake()->streetAddress(),
            'region' => 'Greater Accra',
            'city' => fake()->city(),
            'landmark' => fake()->optional()->sentence(3),
            'delivery_note' => fake()->optional()->sentence(),
            'payment_method' => PaymentMethod::Momo,
            'payment_status' => PaymentStatus::Pending,
            'momo_name' => fake()->name(),
            'momo_phone' => '0'.fake()->numerify('#########'),
            'momo_network' => 'mtn',
            'status' => OrderStatus::Confirmed,
            'confirmed_at' => now(),
        ];
    }

    public function onTheWay(): static
    {
        return $this->state(fn () => [
            'status' => OrderStatus::OnTheWay,
            'dispatched_at' => now(),
        ]);
    }

    public function delivered(): static
    {
        return $this->state(fn () => [
            'status' => OrderStatus::Delivered,
            'dispatched_at' => now()->subHour(),
            'delivered_at' => now(),
            'payment_status' => PaymentStatus::Paid,
        ]);
    }

    public function cancelled(): static
    {
        return $this->state(fn () => [
            'status' => OrderStatus::Cancelled,
        ]);
    }

    public function cashOnDelivery(): static
    {
        return $this->state(fn () => [
            'payment_method' => PaymentMethod::Cod,
            'momo_name' => null,
            'momo_phone' => null,
            'momo_network' => null,
        ]);
    }
}
