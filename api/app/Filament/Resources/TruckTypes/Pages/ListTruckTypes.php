<?php

namespace App\Filament\Resources\TruckTypes\Pages;

use App\Filament\Resources\TruckTypes\TruckTypeResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListTruckTypes extends ListRecords
{
    protected static string $resource = TruckTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
