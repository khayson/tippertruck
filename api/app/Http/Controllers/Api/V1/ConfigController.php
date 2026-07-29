<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Enums\IssueType;
use App\Enums\MomoNetwork;
use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\SandType;
use App\Models\TruckType;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class ConfigController extends Controller
{
    use ApiResponse;

    public function __invoke(): JsonResponse
    {
        $sandTypes = SandType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'name', 'slug', 'description', 'icon']);

        $truckTypes = TruckType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'name', 'slug', 'capacity_label', 'price_ghs', 'is_popular']);

        $latestUpdate = Carbon::parse(max(
            SandType::max('updated_at') ?? now(),
            TruckType::max('updated_at') ?? now(),
        ));

        return $this->success([
            'sand_types' => $sandTypes,
            'truck_types' => $truckTypes,
            'regions' => config('ghana.regions'),
            'issue_types' => collect(IssueType::cases())->map(fn (IssueType $t) => [
                'value' => $t->value,
                'label' => str_replace('_', ' ', ucfirst($t->value)),
            ]),
            'payment_networks' => [
                ['value' => MomoNetwork::Mtn->value, 'label' => 'MTN MoMo'],
                ['value' => MomoNetwork::Telecel->value, 'label' => 'Telecel Cash'],
                ['value' => MomoNetwork::AirtelTigo->value, 'label' => 'AirtelTigo Money'],
            ],
            'config_version' => $latestUpdate->toISOString(),
        ]);
    }
}
