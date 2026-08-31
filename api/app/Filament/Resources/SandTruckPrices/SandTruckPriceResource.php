<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTruckPrices;

use App\Filament\Concerns\AdminOnlyResource;
use App\Filament\Resources\SandTruckPrices\Pages\CreateSandTruckPrice;
use App\Filament\Resources\SandTruckPrices\Pages\EditSandTruckPrice;
use App\Filament\Resources\SandTruckPrices\Pages\ListSandTruckPrices;
use App\Filament\Resources\SandTruckPrices\Schemas\SandTruckPriceForm;
use App\Filament\Resources\SandTruckPrices\Tables\SandTruckPricesTable;
use App\Models\SandTruckPrice;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class SandTruckPriceResource extends Resource
{
    use AdminOnlyResource;

    protected static ?string $model = SandTruckPrice::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCurrencyDollar;

    protected static string|UnitEnum|null $navigationGroup = 'Catalog';

    protected static ?int $navigationSort = 3;

    protected static ?string $navigationLabel = 'Prices';

    protected static ?string $modelLabel = 'sand × truck price';

    protected static ?string $pluralModelLabel = 'prices';

    public static function form(Schema $schema): Schema
    {
        return SandTruckPriceForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return SandTruckPricesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListSandTruckPrices::route('/'),
            'create' => CreateSandTruckPrice::route('/create'),
            'edit' => EditSandTruckPrice::route('/{record}/edit'),
        ];
    }
}
