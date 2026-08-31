<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use App\Services\Payments\PaymentGateway;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class OrderService
{
    private const MAX_REF_RETRIES = 3;

    public function __construct(
        private readonly PricingService $pricingService,
        private readonly PaymentGateway $paymentGateway,
    ) {}

    public function create(array $data, User $user): Order
    {
        $sandType = SandType::findOrFail($data['sand_type_id']);
        $truckType = TruckType::findOrFail($data['truck_type_id']);

        $quote = $this->pricingService->quote($sandType, $truckType, $data['region']);
        $paymentMethod = PaymentMethod::from($data['payment_method']);

        $attempts = 0;

        while (true) {
            try {
                return DB::transaction(function () use ($data, $user, $quote, $paymentMethod) {
                    $order = Order::create([
                        'order_ref' => $this->generateOrderRef(),
                        'user_id' => $user->id,
                        'sand_type_id' => $data['sand_type_id'],
                        'truck_type_id' => $data['truck_type_id'],
                        'price_ghs' => $quote['price_ghs'],
                        'delivery_fee_ghs' => $quote['delivery_fee_ghs'],
                        'total_ghs' => $quote['total_ghs'],
                        'recipient_name' => $data['recipient_name'],
                        'recipient_phone' => $data['recipient_phone'],
                        'street_address' => $data['street_address'],
                        'region' => $data['region'],
                        'city' => $data['city'],
                        'landmark' => $data['landmark'] ?? null,
                        'delivery_note' => $data['delivery_note'] ?? null,
                        'payment_method' => $paymentMethod,
                        'momo_name' => $data['momo_name'] ?? null,
                        'momo_phone' => $data['momo_phone'] ?? null,
                        'momo_network' => $data['momo_network'] ?? null,
                        'status' => OrderStatus::Confirmed,
                        'payment_status' => PaymentStatus::Pending,
                        'confirmed_at' => now(),
                    ]);

                    if ($paymentMethod === PaymentMethod::Momo) {
                        $result = $this->paymentGateway->charge($order);

                        if (! $result->isSuccessful()) {
                            throw ValidationException::withMessages([
                                'payment_method' => [$result->message ?? 'MoMo payment failed. Please try again.'],
                            ]);
                        }

                        $order->payment_status = $result->status;
                        $order->save();
                    }

                    OrderStatusLog::create([
                        'order_id' => $order->id,
                        'old_status' => null,
                        'new_status' => OrderStatus::Confirmed,
                        'changed_by' => $user->id,
                        'note' => 'Order placed',
                        'created_at' => now(),
                    ]);

                    return $order->load(['sandType', 'truckType', 'statusLogs']);
                });
            } catch (UniqueConstraintViolationException $e) {
                $attempts++;
                if ($attempts >= self::MAX_REF_RETRIES) {
                    throw new RuntimeException('Unable to generate a unique order reference after '.self::MAX_REF_RETRIES.' attempts.');
                }
            }
        }
    }

    private function generateOrderRef(): string
    {
        $date = now()->format('Ymd');
        $prefix = "TT-{$date}-";

        $lastSeq = Order::where('order_ref', 'like', "{$prefix}%")
            ->selectRaw('MAX(CAST(SUBSTRING(order_ref, -4) AS UNSIGNED)) as max_seq')
            ->value('max_seq') ?? 0;

        return $prefix.str_pad((string) ($lastSeq + 1), 4, '0', STR_PAD_LEFT);
    }
}
