<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Filament\Resources\OrderResource\Pages;
use App\Filament\Resources\OrderResource\RelationManagers\StatusLogsRelationManager;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderStatusService;
use Filament\Actions;
use Filament\Forms;
use Filament\Infolists;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Validation\ValidationException;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-shopping-bag';

    protected static ?int $navigationSort = 1;

    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();

        $user = auth()->user();

        if ($user instanceof User && $user->role === UserRole::Operator) {
            $query->where('assigned_operator_id', $user->id);
        }

        return $query;
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('order_ref')
                    ->label('Order Ref')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Customer')
                    ->searchable(),
                Tables\Columns\TextColumn::make('sandType.name')
                    ->label('Sand Type'),
                Tables\Columns\TextColumn::make('truckType.name')
                    ->label('Truck Type'),
                Tables\Columns\TextColumn::make('region')
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_ghs')
                    ->label('Total (GHS)')
                    ->money('GHS')
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (OrderStatus $state): string => match ($state) {
                        OrderStatus::Confirmed => 'warning',
                        OrderStatus::OnTheWay => 'info',
                        OrderStatus::Delivered => 'success',
                        OrderStatus::Cancelled => 'danger',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options(collect(OrderStatus::cases())->mapWithKeys(
                        fn (OrderStatus $s) => [$s->value => $s->label()]
                    )),
                Tables\Filters\SelectFilter::make('region')
                    ->options(fn () => Order::query()->distinct()->pluck('region', 'region')->toArray()),
                Tables\Filters\Filter::make('created_at')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'], fn (Builder $q, $date) => $q->whereDate('created_at', '>=', $date))
                            ->when($data['until'], fn (Builder $q, $date) => $q->whereDate('created_at', '<=', $date));
                    }),
            ])
            ->actions([
                Actions\Action::make('mark_on_the_way')
                    ->label('Mark On The Way')
                    ->icon('heroicon-o-truck')
                    ->color('info')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record): bool => $record->status === OrderStatus::Confirmed)
                    ->action(function (Order $record): void {
                        try {
                            app(OrderStatusService::class)->transition($record, OrderStatus::OnTheWay, auth()->user(), 'Dispatched via admin panel');
                            Notification::make()->title('Order marked as On The Way')->success()->send();
                        } catch (ValidationException $e) {
                            Notification::make()->title($e->getMessage())->danger()->send();
                        }
                    }),
                Actions\Action::make('mark_delivered')
                    ->label('Mark Delivered')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record): bool => $record->status === OrderStatus::OnTheWay)
                    ->action(function (Order $record): void {
                        try {
                            app(OrderStatusService::class)->transition($record, OrderStatus::Delivered, auth()->user(), 'Delivered via admin panel');
                            Notification::make()->title('Order marked as Delivered')->success()->send();
                        } catch (ValidationException $e) {
                            Notification::make()->title($e->getMessage())->danger()->send();
                        }
                    }),
                Actions\Action::make('cancel')
                    ->label('Cancel')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record): bool => in_array($record->status, [OrderStatus::Confirmed, OrderStatus::OnTheWay], true))
                    ->action(function (Order $record): void {
                        try {
                            app(OrderStatusService::class)->transition($record, OrderStatus::Cancelled, auth()->user(), 'Cancelled via admin panel');
                            Notification::make()->title('Order cancelled')->success()->send();
                        } catch (ValidationException $e) {
                            Notification::make()->title($e->getMessage())->danger()->send();
                        }
                    }),
                Actions\Action::make('assign_operator')
                    ->label('Assign Operator')
                    ->icon('heroicon-o-user-plus')
                    ->visible(fn (): bool => auth()->user()->role === UserRole::Admin)
                    ->form([
                        Forms\Components\Select::make('assigned_operator_id')
                            ->label('Operator')
                            ->options(User::where('role', UserRole::Operator)->pluck('name', 'id'))
                            ->required(),
                    ])
                    ->action(function (Order $record, array $data): void {
                        $record->update(['assigned_operator_id' => $data['assigned_operator_id']]);
                        Notification::make()->title('Operator assigned')->success()->send();
                    }),
                Actions\ViewAction::make(),
            ]);
    }

    public static function infolist(Schema $infolist): Schema
    {
        return $infolist
            ->schema([
                Section::make('Order Details')
                    ->schema([
                        Infolists\Components\TextEntry::make('order_ref')->label('Order Ref'),
                        Infolists\Components\TextEntry::make('status')
                            ->badge()
                            ->color(fn (OrderStatus $state): string => match ($state) {
                                OrderStatus::Confirmed => 'warning',
                                OrderStatus::OnTheWay => 'info',
                                OrderStatus::Delivered => 'success',
                                OrderStatus::Cancelled => 'danger',
                            }),
                        Infolists\Components\TextEntry::make('sandType.name')->label('Sand Type'),
                        Infolists\Components\TextEntry::make('truckType.name')->label('Truck Type'),
                        Infolists\Components\TextEntry::make('created_at')->dateTime(),
                    ])->columns(3),
                Section::make('Delivery')
                    ->schema([
                        Infolists\Components\TextEntry::make('recipient_name'),
                        Infolists\Components\TextEntry::make('recipient_phone'),
                        Infolists\Components\TextEntry::make('street_address'),
                        Infolists\Components\TextEntry::make('region'),
                        Infolists\Components\TextEntry::make('city'),
                        Infolists\Components\TextEntry::make('landmark')->placeholder('—'),
                        Infolists\Components\TextEntry::make('delivery_note')->placeholder('—'),
                        Infolists\Components\TextEntry::make('assignedOperator.name')
                            ->label('Assigned Operator')
                            ->placeholder('Unassigned'),
                    ])->columns(2),
                Section::make('Pricing')
                    ->schema([
                        Infolists\Components\TextEntry::make('price_ghs')->label('Base Price (GHS)')->money('GHS'),
                        Infolists\Components\TextEntry::make('delivery_fee_ghs')->label('Delivery Surcharge (GHS)')->money('GHS'),
                        Infolists\Components\TextEntry::make('total_ghs')->label('Total (GHS)')->money('GHS'),
                    ])->columns(3),
                Section::make('Payment')
                    ->schema([
                        Infolists\Components\TextEntry::make('payment_method')
                            ->formatStateUsing(fn ($state) => $state?->value === 'momo' ? 'MoMo' : 'Cash on Delivery'),
                        Infolists\Components\TextEntry::make('payment_status'),
                        Infolists\Components\TextEntry::make('momo_network')
                            ->placeholder('—'),
                        Infolists\Components\TextEntry::make('momo_phone')
                            ->formatStateUsing(function (?string $state): string {
                                if ($state === null || strlen($state) < 4) {
                                    return '—';
                                }

                                return substr($state, 0, 3).str_repeat('*', strlen($state) - 5).substr($state, -2);
                            }),
                    ])->columns(2),
                Section::make('Timestamps')
                    ->schema([
                        Infolists\Components\TextEntry::make('confirmed_at')->dateTime()->placeholder('—'),
                        Infolists\Components\TextEntry::make('dispatched_at')->dateTime()->placeholder('—'),
                        Infolists\Components\TextEntry::make('delivered_at')->dateTime()->placeholder('—'),
                    ])->columns(3),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            StatusLogsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'view' => Pages\ViewOrder::route('/{record}'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
