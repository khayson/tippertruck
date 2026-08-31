<?php

declare(strict_types=1);

namespace App\Filament\Resources\SandTypes\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Str;

class SandTypeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Sand type')
                    ->columns(2)
                    ->components([
                        TextInput::make('name')
                            ->required()
                            ->live(onBlur: true)
                            ->afterStateUpdated(function (?string $state, callable $set, ?string $operation): void {
                                if ($operation === 'create' && filled($state)) {
                                    $set('slug', Str::slug($state));
                                }
                            }),
                        TextInput::make('slug')
                            ->required()
                            ->unique(ignoreRecord: true),
                        Textarea::make('description')
                            ->required()
                            ->columnSpanFull(),
                        FileUpload::make('image')
                            ->label('Sand image')
                            ->image()
                            ->disk('public')
                            ->directory('sand-types')
                            ->visibility('public')
                            ->imageEditor()
                            ->maxSize(4096)
                            ->helperText('Shown on the Home sand cards in the mobile app. Run `php artisan storage:link` once so uploads are publicly reachable.')
                            ->columnSpanFull(),
                        TextInput::make('icon')
                            ->nullable()
                            ->helperText('Optional icon key for clients that do not use the image.'),
                        TextInput::make('sort_order')->numeric()->default(0)->required(),
                        Toggle::make('is_active')->default(true),
                    ]),
            ]);
    }
}
