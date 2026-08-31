<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Enums\IssueType;
use App\Enums\MomoNetwork;
use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\DeliveryZone;
use App\Models\SandTruckPrice;
use App\Models\SandType;
use App\Models\TruckType;
use App\Services\SocialAuth\SocialAuthManager;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;

class ConfigController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly SocialAuthManager $socialAuth) {}

    public function __invoke(): JsonResponse
    {
        $sandTypes = SandType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'name', 'slug', 'description', 'icon', 'image'])
            ->map(fn (SandType $sand): array => [
                'id' => $sand->id,
                'name' => $sand->name,
                'slug' => $sand->slug,
                'description' => $sand->description,
                'icon' => $sand->icon,
                'image_url' => $sand->imageUrl(),
            ]);

        $truckTypes = TruckType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['id', 'name', 'slug', 'capacity_label', 'price_ghs', 'is_popular']);

        $activeRegions = DeliveryZone::where('is_active', true)
            ->orderBy('region')
            ->pluck('region');

        $deliveryZones = DeliveryZone::where('is_active', true)
            ->orderBy('region')
            ->get(['region', 'surcharge_ghs']);

        $priceMatrix = SandTruckPrice::all(['sand_type_id', 'truck_type_id', 'price_ghs']);

        $latestUpdate = Carbon::parse(max(
            SandType::max('updated_at') ?? now(),
            TruckType::max('updated_at') ?? now(),
            SandTruckPrice::max('updated_at') ?? now(),
            DeliveryZone::max('updated_at') ?? now(),
        ));

        return $this->success([
            'sand_types' => $sandTypes,
            'truck_types' => $truckTypes,
            'price_matrix' => $priceMatrix,
            'delivery_zones' => $deliveryZones,
            'regions' => $activeRegions,
            'issue_types' => collect(IssueType::cases())->map(fn (IssueType $t) => [
                'value' => $t->value,
                'label' => str_replace('_', ' ', ucfirst($t->value)),
            ]),
            'payment_networks' => [
                ['value' => MomoNetwork::Mtn->value, 'label' => 'MTN MoMo'],
                ['value' => MomoNetwork::Telecel->value, 'label' => 'Telecel Cash'],
                ['value' => MomoNetwork::AirtelTigo->value, 'label' => 'AirtelTigo Money'],
            ],
            'social_auth' => $this->socialAuth->configPayload(),
            'config_version' => $latestUpdate->toISOString(),
        ]);
    }
}
