<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\TruckType;
use Illuminate\Database\Seeder;

class TruckTypeSeeder extends Seeder
{
    public function run(): void
    {
        $types = [
            ['name' => 'Small Truck', 'slug' => 'small', 'capacity_label' => '1–3 tonnes', 'capacity_tonnes_min' => 1.0, 'capacity_tonnes_max' => 3.0, 'price_ghs' => 250.00, 'is_popular' => false, 'sort_order' => 1],
            ['name' => 'Medium Truck', 'slug' => 'medium', 'capacity_label' => '4–7 tonnes', 'capacity_tonnes_min' => 4.0, 'capacity_tonnes_max' => 7.0, 'price_ghs' => 450.00, 'is_popular' => true, 'sort_order' => 2],
            ['name' => 'Large Truck', 'slug' => 'large', 'capacity_label' => '8+ tonnes', 'capacity_tonnes_min' => 8.0, 'capacity_tonnes_max' => 15.0, 'price_ghs' => 700.00, 'is_popular' => false, 'sort_order' => 3],
        ];

        foreach ($types as $type) {
            TruckType::updateOrCreate(['slug' => $type['slug']], $type);
        }
    }
}
