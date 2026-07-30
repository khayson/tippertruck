<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\DeliveryZone;
use App\Models\SandTruckPrice;
use App\Models\SandType;
use App\Models\TruckType;
use Illuminate\Validation\ValidationException;

class PricingService
{
    /**
     * @return array{price_ghs: string, delivery_fee_ghs: string, total_ghs: string}
     */
    public function quote(SandType $sandType, TruckType $truckType, string $region): array
    {
        $matrixPrice = SandTruckPrice::where('sand_type_id', $sandType->id)
            ->where('truck_type_id', $truckType->id)
            ->first();

        if ($matrixPrice === null) {
            throw ValidationException::withMessages([
                'sand_type_id' => ['No price configured for this sand type and truck combination.'],
            ]);
        }

        $zone = DeliveryZone::where('region', $region)
            ->where('is_active', true)
            ->first();

        if ($zone === null) {
            throw ValidationException::withMessages([
                'region' => ['We do not currently deliver to this region.'],
            ]);
        }

        $base = (float) $matrixPrice->price_ghs;
        $surcharge = (float) $zone->surcharge_ghs;
        $total = $base + $surcharge;

        return [
            'price_ghs' => number_format($base, 2, '.', ''),
            'delivery_fee_ghs' => number_format($surcharge, 2, '.', ''),
            'total_ghs' => number_format($total, 2, '.', ''),
        ];
    }
}
