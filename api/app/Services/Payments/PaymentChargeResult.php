<?php

declare(strict_types=1);

namespace App\Services\Payments;

use App\Enums\PaymentStatus;

final class PaymentChargeResult
{
    public function __construct(
        public readonly PaymentStatus $status,
        public readonly ?string $reference = null,
        public readonly ?string $message = null,
    ) {}

    public function isSuccessful(): bool
    {
        return $this->status === PaymentStatus::Paid;
    }
}
