<?php

declare(strict_types=1);

namespace App\Filament\Resources\DeliveryZoneResource\Pages;

use App\Filament\Resources\DeliveryZoneResource;
use Filament\Actions;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\QueryException;
use Illuminate\Validation\ValidationException;

class EditDeliveryZone extends EditRecord
{
    protected static string $resource = DeliveryZoneResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make()
                ->action(function ($record) {
                    try {
                        $record->delete();
                    } catch (ValidationException $e) {
                        Notification::make()
                            ->title(collect($e->errors())->flatten()->first())
                            ->danger()
                            ->send();
                    } catch (QueryException) {
                        Notification::make()
                            ->title('This delivery zone is referenced by existing orders and cannot be deleted.')
                            ->danger()
                            ->send();
                    }
                }),
        ];
    }
}
