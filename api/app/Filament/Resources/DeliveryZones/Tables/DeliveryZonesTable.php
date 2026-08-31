<?php

declare(strict_types=1);

namespace App\Filament\Resources\DeliveryZones\Tables;

use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class DeliveryZonesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('region')
            ->columns([
                TextColumn::make('region')->searchable()->sortable(),
                TextColumn::make('surcharge_ghs')
                    ->label('Surcharge (GHS)')
                    ->numeric(decimalPlaces: 2)
                    ->sortable(),
                IconColumn::make('is_active')->boolean(),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([]);
    }
}
