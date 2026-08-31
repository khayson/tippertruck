<?php

declare(strict_types=1);

namespace App\Filament\Resources\Issues\Tables;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use App\Models\Issue;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class IssuesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                TextColumn::make('user.name')
                    ->label('Customer')
                    ->searchable(),
                TextColumn::make('order.order_ref')
                    ->label('Order')
                    ->placeholder('—'),
                TextColumn::make('issue_type')
                    ->badge()
                    ->formatStateUsing(fn (IssueType $state): string => str_replace('_', ' ', $state->value)),
                TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (IssueStatus $state): string => str_replace('_', ' ', $state->value))
                    ->color(fn (IssueStatus $state): string => match ($state) {
                        IssueStatus::Open => 'warning',
                        IssueStatus::InReview => 'info',
                        IssueStatus::Resolved => 'success',
                        IssueStatus::Closed => 'gray',
                    }),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('resolved_at')
                    ->dateTime()
                    ->placeholder('—')
                    ->toggleable(),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->options(collect(IssueStatus::cases())->mapWithKeys(
                        fn (IssueStatus $status) => [$status->value => str_replace('_', ' ', ucfirst($status->value))],
                    )),
                SelectFilter::make('issue_type')
                    ->options(collect(IssueType::cases())->mapWithKeys(
                        fn (IssueType $type) => [$type->value => str_replace('_', ' ', $type->value)],
                    )),
            ])
            ->recordActions([
                ViewAction::make(),
                EditAction::make(),
                Action::make('resolve')
                    ->label('Resolve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->form([
                        Textarea::make('admin_response')
                            ->label('Response to customer')
                            ->required()
                            ->rows(4),
                    ])
                    ->visible(fn (Issue $record): bool => $record->status !== IssueStatus::Resolved
                        && $record->status !== IssueStatus::Closed)
                    ->action(function (Issue $record, array $data): void {
                        $record->update([
                            'admin_response' => $data['admin_response'],
                            'status' => IssueStatus::Resolved,
                            'resolved_at' => now(),
                        ]);

                        Notification::make()
                            ->title('Issue resolved')
                            ->success()
                            ->send();
                    }),
            ])
            ->toolbarActions([]);
    }
}
