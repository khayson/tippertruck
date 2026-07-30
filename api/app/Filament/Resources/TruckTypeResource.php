<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Enums\UserRole;
use App\Filament\Resources\TruckTypeResource\Pages;
use App\Models\TruckType;
use Filament\Actions;
use Filament\Forms;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class TruckTypeResource extends Resource
{
    protected static ?string $model = TruckType::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-truck';

    protected static string|\UnitEnum|null $navigationGroup = 'Pricing';

    protected static ?int $navigationSort = 6;

    public static function canAccess(): bool
    {
        return auth()->user()?->role === UserRole::Admin;
    }

    public static function form(Schema $form): Schema
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')->required()->maxLength(255),
                Forms\Components\TextInput::make('slug')->required()->maxLength(255),
                Forms\Components\TextInput::make('capacity_label')->required()->maxLength(255),
                Forms\Components\TextInput::make('capacity_tonnes_min')->numeric()->required(),
                Forms\Components\TextInput::make('capacity_tonnes_max')->numeric()->nullable(),
                Forms\Components\TextInput::make('price_ghs')
                    ->label('Legacy Price (GHS)')
                    ->numeric()
                    ->prefix('GHS')
                    ->helperText('Deprecated — use the price matrix instead'),
                Forms\Components\Toggle::make('is_popular')->default(false),
                Forms\Components\Toggle::make('is_active')->default(true),
                Forms\Components\TextInput::make('sort_order')->numeric()->default(0),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->sortable()->searchable(),
                Tables\Columns\TextColumn::make('capacity_label'),
                Tables\Columns\TextColumn::make('price_ghs')->label('Legacy Price')->money('GHS'),
                Tables\Columns\IconColumn::make('is_popular')->boolean(),
                Tables\Columns\IconColumn::make('is_active')->boolean(),
                Tables\Columns\TextColumn::make('sort_order')->sortable(),
            ])
            ->defaultSort('sort_order')
            ->actions([
                Actions\EditAction::make(),
            ])
            ->bulkActions([])
            ->headerActions([
                Actions\CreateAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTruckTypes::route('/'),
            'edit' => Pages\EditTruckType::route('/{record}/edit'),
        ];
    }
}
