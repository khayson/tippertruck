<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Enums\UserRole;
use App\Filament\Resources\SandTruckPriceResource\Pages;
use App\Models\SandTruckPrice;
use App\Models\SandType;
use App\Models\TruckType;
use Filament\Actions;
use Filament\Forms;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class SandTruckPriceResource extends Resource
{
    protected static ?string $model = SandTruckPrice::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-currency-dollar';

    protected static string|\UnitEnum|null $navigationGroup = 'Pricing';

    protected static ?string $navigationLabel = 'Price Matrix';

    protected static ?int $navigationSort = 7;

    public static function canAccess(): bool
    {
        return auth()->user()?->role === UserRole::Admin;
    }

    public static function form(Schema $form): Schema
    {
        return $form
            ->schema([
                Forms\Components\Select::make('sand_type_id')
                    ->label('Sand Type')
                    ->options(SandType::pluck('name', 'id'))
                    ->required(),
                Forms\Components\Select::make('truck_type_id')
                    ->label('Truck Type')
                    ->options(TruckType::pluck('name', 'id'))
                    ->required(),
                Forms\Components\TextInput::make('price_ghs')
                    ->label('Price (GHS)')
                    ->numeric()
                    ->prefix('GHS')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('sandType.name')->label('Sand Type')->sortable(),
                Tables\Columns\TextColumn::make('truckType.name')->label('Truck Type')->sortable(),
                Tables\Columns\TextColumn::make('price_ghs')->label('Price (GHS)')->money('GHS')->sortable(),
            ])
            ->defaultSort('sand_type_id')
            ->actions([
                Actions\EditAction::make(),
            ])
            ->headerActions([
                Actions\CreateAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListSandTruckPrices::route('/'),
            'edit' => Pages\EditSandTruckPrice::route('/{record}/edit'),
        ];
    }
}
