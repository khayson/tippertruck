<?php

declare(strict_types=1);

namespace App\Filament\Resources\Issues\Schemas;

use App\Enums\IssueStatus;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class IssueForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Admin response')
                    ->components([
                        Select::make('status')
                            ->options(collect(IssueStatus::cases())->mapWithKeys(
                                fn (IssueStatus $status) => [$status->value => str_replace('_', ' ', ucfirst($status->value))],
                            ))
                            ->required()
                            ->native(false),
                        Textarea::make('admin_response')
                            ->label('Response to customer')
                            ->rows(4)
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
