<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Enums\MomoNetwork;
use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment('local', 'testing')) {
            $this->command?->info('OrderSeeder skipped — not in local or testing environment.');

            return;
        }

        if (Order::exists()) {
            $this->command?->info('OrderSeeder skipped — orders already exist.');

            return;
        }

        $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
        $operator = User::where('email', 'operator@tippertruck.test')->firstOrFail();
        $sandTypes = SandType::all();
        $truckTypes = TruckType::all();

        $orders = [
            ['status' => OrderStatus::Confirmed, 'sand' => 0, 'truck' => 0, 'payment' => PaymentMethod::Momo],
            ['status' => OrderStatus::Confirmed, 'sand' => 1, 'truck' => 1, 'payment' => PaymentMethod::Cod],
            ['status' => OrderStatus::OnTheWay, 'sand' => 0, 'truck' => 1, 'payment' => PaymentMethod::Momo],
            ['status' => OrderStatus::OnTheWay, 'sand' => 2, 'truck' => 2, 'payment' => PaymentMethod::Momo],
            ['status' => OrderStatus::Delivered, 'sand' => 1, 'truck' => 0, 'payment' => PaymentMethod::Cod],
            ['status' => OrderStatus::Delivered, 'sand' => 0, 'truck' => 1, 'payment' => PaymentMethod::Momo],
            ['status' => OrderStatus::Delivered, 'sand' => 2, 'truck' => 2, 'payment' => PaymentMethod::Momo],
            ['status' => OrderStatus::Cancelled, 'sand' => 1, 'truck' => 0, 'payment' => PaymentMethod::Cod],
        ];

        $regions = ['Greater Accra', 'Ashanti', 'Central'];
        $cities = ['Accra', 'Kumasi', 'Cape Coast'];

        foreach ($orders as $i => $spec) {
            $truck = $truckTypes[$spec['truck']];
            $isMomo = $spec['payment'] === PaymentMethod::Momo;
            $createdAt = now()->subDays(7 - $i)->subHours(rand(1, 12));

            $order = Order::create([
                'order_ref' => sprintf('TT-%s-%04d', $createdAt->format('Ymd'), $i + 1),
                'user_id' => $client->id,
                'sand_type_id' => $sandTypes[$spec['sand']]->id,
                'truck_type_id' => $truck->id,
                'price_ghs' => $truck->price_ghs,
                'delivery_fee_ghs' => 0,
                'total_ghs' => $truck->price_ghs,
                'recipient_name' => 'Kofi Mensah',
                'recipient_phone' => '0241234567',
                'street_address' => 'No. '.($i + 1).' Demo Street',
                'region' => $regions[$i % 3],
                'city' => $cities[$i % 3],
                'landmark' => $i % 2 === 0 ? 'Near the market' : null,
                'delivery_note' => $i % 3 === 0 ? 'Call on arrival' : null,
                'payment_method' => $spec['payment'],
                'payment_status' => $spec['status'] === OrderStatus::Delivered ? PaymentStatus::Paid : PaymentStatus::Pending,
                'momo_name' => $isMomo ? 'Kofi Mensah' : null,
                'momo_phone' => $isMomo ? '0241234567' : null,
                'momo_network' => $isMomo ? MomoNetwork::Mtn : null,
                'status' => $spec['status'],
                'assigned_operator_id' => in_array($spec['status'], [OrderStatus::OnTheWay, OrderStatus::Delivered], true) ? $operator->id : null,
                'confirmed_at' => $createdAt,
                'dispatched_at' => in_array($spec['status'], [OrderStatus::OnTheWay, OrderStatus::Delivered], true) ? $createdAt->copy()->addHours(2) : null,
                'delivered_at' => $spec['status'] === OrderStatus::Delivered ? $createdAt->copy()->addHours(5) : null,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]);

            $this->createStatusLog($order, $spec['status'], $createdAt, $operator->id);
        }
    }

    private function createStatusLog(Order $order, OrderStatus $finalStatus, $createdAt, int $operatorId): void
    {
        OrderStatusLog::create([
            'order_id' => $order->id,
            'old_status' => null,
            'new_status' => OrderStatus::Confirmed,
            'changed_by' => null,
            'note' => 'Order placed',
            'created_at' => $createdAt,
        ]);

        if ($finalStatus === OrderStatus::Cancelled) {
            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => OrderStatus::Confirmed,
                'new_status' => OrderStatus::Cancelled,
                'changed_by' => $order->user_id,
                'note' => 'Cancelled by client',
                'created_at' => $createdAt->copy()->addMinutes(30),
            ]);

            return;
        }

        if (in_array($finalStatus, [OrderStatus::OnTheWay, OrderStatus::Delivered], true)) {
            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => OrderStatus::Confirmed,
                'new_status' => OrderStatus::OnTheWay,
                'changed_by' => $operatorId,
                'note' => 'Dispatched',
                'created_at' => $createdAt->copy()->addHours(2),
            ]);
        }

        if ($finalStatus === OrderStatus::Delivered) {
            OrderStatusLog::create([
                'order_id' => $order->id,
                'old_status' => OrderStatus::OnTheWay,
                'new_status' => OrderStatus::Delivered,
                'changed_by' => $operatorId,
                'note' => 'Delivered',
                'created_at' => $createdAt->copy()->addHours(5),
            ]);
        }
    }
}
