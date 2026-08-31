<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTruckPrices\Tables;

use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class SandTruckPricesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('id')
            ->columns([
                TextColumn::make('sandType.name')->label('Sand')->searchable()->sortable(),
                TextColumn::make('truckType.name')->label('Truck')->searchable()->sortable(),
                TextColumn::make('price_ghs')
                    ->label('Price (GHS)')
                    ->numeric(decimalPlaces: 2)
                    ->sortable(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([]);
    }
}
