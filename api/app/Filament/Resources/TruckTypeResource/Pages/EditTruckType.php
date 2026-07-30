<?php

declare(strict_types=1);

namespace App\Filament\Resources\TruckTypeResource\Pages;

use App\Filament\Resources\TruckTypeResource;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\QueryException;

class EditTruckType extends EditRecord
{
    protected static string $resource = TruckTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->action(function ($record) {
                    try {
                        $record->delete();
                    } catch (QueryException) {
                        Notification::make()
                            ->title('This truck type is referenced by existing orders and cannot be deleted. Deactivate it instead.')
                            ->danger()
                            ->send();
                    }
                }),
        ];
    }
}
