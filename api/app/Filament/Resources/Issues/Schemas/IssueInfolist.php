<?php

declare(strict_types=1);

namespace App\Filament\Resources\Issues\Schemas;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class IssueInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Issue')
                    ->columns(2)
                    ->components([
                        TextEntry::make('user.name')->label('Customer'),
                        TextEntry::make('order.order_ref')
                            ->label('Order')
                            ->placeholder('—'),
                        TextEntry::make('issue_type')
                            ->badge()
                            ->formatStateUsing(fn (IssueType $state): string => str_replace('_', ' ', $state->value)),
                        TextEntry::make('status')
                            ->badge()
                            ->formatStateUsing(fn (IssueStatus $state): string => str_replace('_', ' ', $state->value))
                            ->color(fn (IssueStatus $state): string => match ($state) {
                                IssueStatus::Open => 'warning',
                                IssueStatus::InReview => 'info',
                                IssueStatus::Resolved => 'success',
                                IssueStatus::Closed => 'gray',
                            }),
                        TextEntry::make('description')->columnSpanFull(),
                        TextEntry::make('admin_response')
                            ->placeholder('No response yet')
                            ->columnSpanFull(),
                        TextEntry::make('resolved_at')->dateTime()->placeholder('—'),
                        TextEntry::make('created_at')->dateTime(),
                    ]),
            ]);
    }
}
