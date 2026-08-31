<?php

namespace App\Filament\Resources\TruckTypes\Pages;

use App\Filament\Resources\TruckTypes\TruckTypeResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditTruckType extends EditRecord
{
    protected static string $resource = TruckTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
