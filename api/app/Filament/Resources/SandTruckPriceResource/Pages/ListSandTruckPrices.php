<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTruckPriceResource\Pages;

use App\Filament\Resources\SandTruckPriceResource;
use Filament\Resources\Pages\ListRecords;

class ListSandTruckPrices extends ListRecords
{
    protected static string $resource = SandTruckPriceResource::class;
}
