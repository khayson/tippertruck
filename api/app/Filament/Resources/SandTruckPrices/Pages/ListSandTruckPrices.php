<?php

namespace App\Filament\Resources\SandTruckPrices\Pages;

use App\Filament\Resources\SandTruckPrices\SandTruckPriceResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListSandTruckPrices extends ListRecords
{
    protected static string $resource = SandTruckPriceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
