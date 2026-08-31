<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders\Schemas;

use App\Enums\UserRole;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Assignment')
                    ->description('Assign an operator so they can dispatch and deliver from the panel or mobile app.')
                    ->components([
                        TextInput::make('order_ref')
                            ->disabled()
                            ->dehydrated(false),
                        Select::make('assigned_operator_id')
                            ->label('Assigned operator')
                            ->relationship(
                                name: 'assignedOperator',
                                titleAttribute: 'name',
                                modifyQueryUsing: fn ($query) => $query->where('role', UserRole::Operator),
                            )
                            ->searchable()
                            ->preload()
                            ->nullable(),
                    ]),
            ]);
    }
}
