<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\DeliveryZone;
use Illuminate\Database\Seeder;

class DeliveryZoneSeeder extends Seeder
{
    public function run(): void
    {
        $zones = [
            ['region' => 'Greater Accra', 'surcharge_ghs' => 0.00, 'is_active' => true],
            ['region' => 'Central', 'surcharge_ghs' => 400.00, 'is_active' => true],
        ];

        foreach ($zones as $zone) {
            DeliveryZone::updateOrCreate(
                ['region' => $zone['region']],
                $zone,
            );
        }
    }
}
