<?php

declare(strict_types=1);

namespace App\Services\Payments;

use App\Models\Order;

interface PaymentGateway
{
    /**
     * Charge the customer for an order. Implementations must never receive or store a PIN.
     */
    public function charge(Order $order): PaymentChargeResult;
}
