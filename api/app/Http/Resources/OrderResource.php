<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_ref' => $this->order_ref,
            'sand_type' => [
                'id' => $this->sandType->id,
                'name' => $this->sandType->name,
            ],
            'truck_type' => [
                'id' => $this->truckType->id,
                'name' => $this->truckType->name,
                'capacity_label' => $this->truckType->capacity_label,
            ],
            'price_ghs' => $this->price_ghs,
            'delivery_fee_ghs' => $this->delivery_fee_ghs,
            'total_ghs' => $this->total_ghs,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'progress_percent' => $this->status->progressPercent(),
            'delivery' => [
                'recipient_name' => $this->recipient_name,
                'recipient_phone' => $this->recipient_phone,
                'street_address' => $this->street_address,
                'region' => $this->region,
                'city' => $this->city,
                'landmark' => $this->landmark,
                'delivery_note' => $this->delivery_note,
            ],
            'payment' => [
                'method' => $this->payment_method?->value,
                'status' => $this->payment_status?->value,
                'network' => $this->momo_network?->value,
                'momo_phone' => $this->maskPhone($this->momo_phone),
            ],
            'confirmed_at' => $this->confirmed_at?->toISOString(),
            'dispatched_at' => $this->dispatched_at?->toISOString(),
            'delivered_at' => $this->delivered_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'status_log' => $this->whenLoaded('statusLogs', fn () => $this->statusLogs->map(fn ($log) => [
                'old_status' => $log->old_status?->value,
                'new_status' => $log->new_status->value,
                'created_at' => $log->created_at?->toISOString(),
            ])),
        ];
    }

    private function maskPhone(?string $phone): ?string
    {
        if (! $phone || strlen($phone) < 7) {
            return $phone;
        }

        return substr($phone, 0, 3).str_repeat('*', strlen($phone) - 5).substr($phone, -2);
    }
}
