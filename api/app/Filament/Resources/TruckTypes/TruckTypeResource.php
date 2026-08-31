<?php

declare(strict_types=1);

namespace App\Filament\Resources\TruckTypes;

use App\Filament\Concerns\AdminOnlyResource;
use App\Filament\Resources\TruckTypes\Pages\CreateTruckType;
use App\Filament\Resources\TruckTypes\Pages\EditTruckType;
use App\Filament\Resources\TruckTypes\Pages\ListTruckTypes;
use App\Filament\Resources\TruckTypes\Schemas\TruckTypeForm;
use App\Filament\Resources\TruckTypes\Tables\TruckTypesTable;
use App\Models\TruckType;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class TruckTypeResource extends Resource
{
    use AdminOnlyResource;

    protected static ?string $model = TruckType::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTruck;

    protected static string|UnitEnum|null $navigationGroup = 'Catalog';

    protected static ?int $navigationSort = 2;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return TruckTypeForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return TruckTypesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTruckTypes::route('/'),
            'create' => CreateTruckType::route('/create'),
            'edit' => EditTruckType::route('/{record}/edit'),
        ];
    }
}
