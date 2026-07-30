<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use App\Models\Issue;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Seeder;

class IssueSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment('local', 'testing')) {
            return;
        }

        if (Issue::exists()) {
            return;
        }

        $client = User::where('email', 'client@tippertruck.test')->firstOrFail();
        $deliveredOrder = Order::where('user_id', $client->id)
            ->where('status', 'delivered')
            ->first();

        Issue::create([
            'user_id' => $client->id,
            'order_id' => $deliveredOrder?->id,
            'issue_type' => IssueType::LateDelivery,
            'description' => 'The delivery arrived three hours after the estimated time. Please look into this.',
            'status' => IssueStatus::Open,
        ]);

        Issue::create([
            'user_id' => $client->id,
            'order_id' => null,
            'issue_type' => IssueType::PaymentIssue,
            'description' => 'I was charged twice for my MoMo payment but only received one delivery.',
            'status' => IssueStatus::Open,
        ]);

        Issue::create([
            'user_id' => $client->id,
            'order_id' => $deliveredOrder?->id,
            'issue_type' => IssueType::WrongSandType,
            'description' => 'I ordered River Sand but received Filling Sand instead.',
            'status' => IssueStatus::Resolved,
            'admin_response' => 'We have arranged a replacement delivery at no extra cost.',
            'resolved_at' => now()->subDay(),
        ]);
    }
}
