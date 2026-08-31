<?php

namespace App\Filament\Resources\SandTypes\Pages;

use App\Filament\Resources\SandTypes\SandTypeResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditSandType extends EditRecord
{
    protected static string $resource = SandTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
