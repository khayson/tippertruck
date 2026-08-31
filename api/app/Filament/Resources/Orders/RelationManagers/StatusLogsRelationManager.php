<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders\RelationManagers;

use App\Enums\OrderStatus;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class StatusLogsRelationManager extends RelationManager
{
    protected static string $relationship = 'statusLogs';

    protected static ?string $title = 'Status log';

    protected static bool $isLazy = true;

    public function table(Table $table): Table
    {
        return $table
            ->deferLoading()
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('created_at')
                    ->label('When')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('old_status')
                    ->label('From')
                    ->getStateUsing(fn ($record): string => $record->old_status?->label() ?? 'New')
                    ->badge()
                    ->color(fn ($record): string => $record->old_status === null ? 'gray' : 'warning'),
                TextColumn::make('new_status')
                    ->label('To')
                    ->formatStateUsing(fn (OrderStatus $state): string => $state->label())
                    ->badge()
                    ->color('warning'),
                TextColumn::make('changedByUser.name')
                    ->label('By')
                    ->placeholder('System'),
                TextColumn::make('note')
                    ->placeholder('—')
                    ->wrap(),
            ])
            ->headerActions([])
            ->recordActions([])
            ->toolbarActions([]);
    }
}
