<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use App\Enums\UserRole;
use App\Filament\Resources\IssueResource\Pages;
use App\Models\Issue;
use Filament\Actions;
use Filament\Forms;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class IssueResource extends Resource
{
    protected static ?string $model = Issue::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-exclamation-triangle';

    protected static ?int $navigationSort = 4;

    public static function canAccess(): bool
    {
        return auth()->user()?->role === UserRole::Admin;
    }

    public static function form(Schema $form): Schema
    {
        return $form
            ->schema([
                Forms\Components\Select::make('issue_type')
                    ->options(collect(IssueType::cases())->mapWithKeys(
                        fn (IssueType $t) => [$t->value => str_replace('_', ' ', ucfirst($t->value))]
                    ))
                    ->disabled(),
                Forms\Components\Textarea::make('description')
                    ->disabled()
                    ->columnSpanFull(),
                Forms\Components\Textarea::make('admin_response')
                    ->label('Admin Response')
                    ->columnSpanFull(),
                Forms\Components\Select::make('status')
                    ->options(collect(IssueStatus::cases())->mapWithKeys(
                        fn (IssueStatus $s) => [$s->value => ucfirst(str_replace('_', ' ', $s->value))]
                    )),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Reported By')
                    ->searchable(),
                Tables\Columns\TextColumn::make('issue_type')
                    ->formatStateUsing(fn (IssueType $state) => str_replace('_', ' ', ucfirst($state->value))),
                Tables\Columns\TextColumn::make('order.order_ref')
                    ->label('Order')
                    ->placeholder('—')
                    ->url(fn (Issue $record) => $record->order_id
                        ? OrderResource::getUrl('view', ['record' => $record->order_id])
                        : null),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (IssueStatus $state): string => match ($state) {
                        IssueStatus::Open => 'danger',
                        IssueStatus::InReview => 'warning',
                        IssueStatus::Resolved => 'success',
                        IssueStatus::Closed => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(collect(IssueStatus::cases())->mapWithKeys(
                        fn (IssueStatus $s) => [$s->value => ucfirst(str_replace('_', ' ', $s->value))]
                    )),
            ])
            ->actions([
                Actions\EditAction::make(),
                Actions\Action::make('resolve')
                    ->label('Resolve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('admin_response')
                            ->label('Admin Response')
                            ->required(),
                    ])
                    ->visible(fn (Issue $record): bool => ! in_array($record->status, [IssueStatus::Resolved, IssueStatus::Closed], true))
                    ->action(function (Issue $record, array $data): void {
                        $record->update([
                            'status' => IssueStatus::Resolved,
                            'admin_response' => $data['admin_response'],
                            'resolved_at' => now(),
                        ]);
                        Notification::make()->title('Issue resolved')->success()->send();
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListIssues::route('/'),
            'edit' => Pages\EditIssue::route('/{record}/edit'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
