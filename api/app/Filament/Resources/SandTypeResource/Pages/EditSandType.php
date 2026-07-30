<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTypeResource\Pages;

use App\Filament\Resources\SandTypeResource;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\QueryException;

class EditSandType extends EditRecord
{
    protected static string $resource = SandTypeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->action(function ($record) {
                    try {
                        $record->delete();
                    } catch (QueryException) {
                        Notification::make()
                            ->title('This sand type is referenced by existing orders and cannot be deleted. Deactivate it instead.')
                            ->danger()
                            ->send();
                    }
                }),
        ];
    }
}
