<?php

namespace App\Filament\Resources\SandTypes\Pages;

use App\Filament\Resources\SandTypes\SandTypeResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListSandTypes extends ListRecords
{
    protected static string $resource = SandTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
