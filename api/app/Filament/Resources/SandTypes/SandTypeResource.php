<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTypes;

use App\Filament\Concerns\AdminOnlyResource;
use App\Filament\Resources\SandTypes\Pages\CreateSandType;
use App\Filament\Resources\SandTypes\Pages\EditSandType;
use App\Filament\Resources\SandTypes\Pages\ListSandTypes;
use App\Filament\Resources\SandTypes\Schemas\SandTypeForm;
use App\Filament\Resources\SandTypes\Tables\SandTypesTable;
use App\Models\SandType;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class SandTypeResource extends Resource
{
    use AdminOnlyResource;

    protected static ?string $model = SandType::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCube;

    protected static string|UnitEnum|null $navigationGroup = 'Catalog';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return SandTypeForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return SandTypesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListSandTypes::route('/'),
            'create' => CreateSandType::route('/create'),
            'edit' => EditSandType::route('/{record}/edit'),
        ];
    }
}
