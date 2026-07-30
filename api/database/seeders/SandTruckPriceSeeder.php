<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\SandTruckPrice;
use App\Models\SandType;
use App\Models\TruckType;
use Illuminate\Database\Seeder;

class SandTruckPriceSeeder extends Seeder
{
    public function run(): void
    {
        $sandTypes = SandType::all()->keyBy('slug');
        $truckTypes = TruckType::all()->keyBy('slug');

        $prices = [
            ['sand' => 'filling-sand', 'truck' => 'small', 'price' => 900.00],
            ['sand' => 'filling-sand', 'truck' => 'medium', 'price' => 1600.00],
            ['sand' => 'filling-sand', 'truck' => 'large', 'price' => 2400.00],
            ['sand' => 'quarry-sand', 'truck' => 'small', 'price' => 1100.00],
            ['sand' => 'quarry-sand', 'truck' => 'medium', 'price' => 1900.00],
            ['sand' => 'quarry-sand', 'truck' => 'large', 'price' => 2800.00],
            ['sand' => 'river-sand', 'truck' => 'small', 'price' => 1300.00],
            ['sand' => 'river-sand', 'truck' => 'medium', 'price' => 2300.00],
            ['sand' => 'river-sand', 'truck' => 'large', 'price' => 3100.00],
        ];

        foreach ($prices as $entry) {
            SandTruckPrice::updateOrCreate(
                [
                    'sand_type_id' => $sandTypes[$entry['sand']]->id,
                    'truck_type_id' => $truckTypes[$entry['truck']]->id,
                ],
                ['price_ghs' => $entry['price']],
            );
        }
    }
}
