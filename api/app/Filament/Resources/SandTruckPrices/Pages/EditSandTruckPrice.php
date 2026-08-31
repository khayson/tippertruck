<?php

namespace App\Filament\Resources\SandTruckPrices\Pages;

use App\Filament\Resources\SandTruckPrices\SandTruckPriceResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditSandTruckPrice extends EditRecord
{
    protected static string $resource = SandTruckPriceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
