<?php

declare(strict_types=1);

namespace App\Services\Payments;

use App\Enums\PaymentStatus;
use App\Models\Order;
use Illuminate\Validation\ValidationException;

class PaymentService
{
    public function markPaid(Order $order): Order
    {
        if ($order->payment_status === PaymentStatus::Paid) {
            return $order;
        }

        if ($order->payment_status === PaymentStatus::Failed) {
            throw ValidationException::withMessages([
                'payment_status' => ['Cannot mark a failed payment as paid. Create a new charge instead.'],
            ]);
        }

        $order->payment_status = PaymentStatus::Paid;
        $order->save();

        return $order->fresh();
    }
}
