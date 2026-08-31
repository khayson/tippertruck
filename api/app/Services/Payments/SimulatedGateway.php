<?php

declare(strict_types=1);

namespace App\Services\Payments;

use App\Enums\PaymentStatus;
use App\Models\Order;

/**
 * Demo gateway — always succeeds. Swap for a Paystack/MoMo adapter later
 * without changing OrderService.
 */
final class SimulatedGateway implements PaymentGateway
{
    public function charge(Order $order): PaymentChargeResult
    {
        return new PaymentChargeResult(
            status: PaymentStatus::Paid,
            reference: 'SIM-'.$order->order_ref,
            message: 'Simulated MoMo charge succeeded',
        );
    }
}
