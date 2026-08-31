<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTruckPrices\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class SandTruckPriceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Matrix price')
                    ->description('This is the live rate card used by /config and order creation.')
                    ->columns(2)
                    ->components([
                        Select::make('sand_type_id')
                            ->relationship('sandType', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),
                        Select::make('truck_type_id')
                            ->relationship('truckType', 'name')
                            ->required()
                            ->searchable()
                            ->preload(),
                        TextInput::make('price_ghs')
                            ->label('Price (GHS)')
                            ->numeric()
                            ->required()
                            ->prefix('GHS'),
                    ]),
            ]);
    }
}
