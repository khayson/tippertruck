<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\SandType;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<SandType> */
class SandTypeFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->words(2, true).' Sand';

        return [
            'name' => $name,
            'slug' => Str::slug($name),
            'description' => fake()->sentence(),
            'icon' => null,
            'is_active' => true,
            'sort_order' => 0,
        ];
    }
}
