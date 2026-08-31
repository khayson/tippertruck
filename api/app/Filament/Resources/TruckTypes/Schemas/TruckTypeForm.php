<?php

declare(strict_types=1);

namespace App\Filament\Resources\TruckTypes\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class TruckTypeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Truck')
                    ->columns(2)
                    ->components([
                        TextInput::make('name')->required()->maxLength(255),
                        TextInput::make('slug')->required()->unique(ignoreRecord: true)->maxLength(255),
                        TextInput::make('capacity_label')->required()->maxLength(255),
                        TextInput::make('capacity_tonnes_min')->numeric()->required(),
                        TextInput::make('capacity_tonnes_max')->numeric()->nullable(),
                        TextInput::make('sort_order')->numeric()->default(0)->required(),
                        Toggle::make('is_popular')->default(false),
                        Toggle::make('is_active')->default(true),
                    ]),
                Section::make('Legacy list price')
                    ->description('Deprecated. Live quotes use Catalog → Prices (sand × truck matrix). Kept for backwards compatibility.')
                    ->collapsed()
                    ->components([
                        TextInput::make('price_ghs')
                            ->label('Deprecated price_ghs')
                            ->numeric()
                            ->required()
                            ->default(0),
                    ]),
            ]);
    }
}
