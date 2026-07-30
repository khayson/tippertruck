<?php

declare(strict_types=1);

namespace App\Filament\Resources\OrderResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class StatusLogsRelationManager extends RelationManager
{
    protected static string $relationship = 'statusLogs';

    protected static ?string $title = 'Status Log';

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('old_status')
                    ->label('From')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('new_status')
                    ->label('To'),
                Tables\Columns\TextColumn::make('changedByUser.name')
                    ->label('Changed By')
                    ->placeholder('System'),
                Tables\Columns\TextColumn::make('note')
                    ->placeholder('—'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'asc');
    }

    public function isReadOnly(): bool
    {
        return true;
    }
}
