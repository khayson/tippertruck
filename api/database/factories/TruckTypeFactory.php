<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\TruckType;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<TruckType> */
class TruckTypeFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->word().' Truck';

        return [
            'name' => $name,
            'slug' => Str::slug($name),
            'capacity_label' => '1–3 tonnes',
            'capacity_tonnes_min' => 1.0,
            'capacity_tonnes_max' => 3.0,
            'price_ghs' => fake()->randomFloat(2, 100, 1000),
            'is_popular' => false,
            'is_active' => true,
            'sort_order' => 0,
        ];
    }
}
