<?php

declare(strict_types=1);

namespace App\Observers;

use App\Models\DeliveryZone;
use Illuminate\Validation\ValidationException;

class DeliveryZoneObserver
{
    public function updating(DeliveryZone $zone): void
    {
        if (! $zone->isDirty('is_active')) {
            return;
        }

        if ($zone->is_active) {
            return;
        }

        $this->assertNotLastActive($zone);
    }

    public function deleting(DeliveryZone $zone): void
    {
        if (! $zone->is_active) {
            return;
        }

        $this->assertNotLastActive($zone);
    }

    private function assertNotLastActive(DeliveryZone $zone): void
    {
        $otherActive = DeliveryZone::where('id', '!=', $zone->id)
            ->where('is_active', true)
            ->exists();

        if (! $otherActive) {
            throw ValidationException::withMessages([
                'data.is_active' => ['Cannot leave zero active delivery zones.'],
            ]);
        }
    }
}
