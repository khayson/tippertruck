<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders\Tables;

use App\Enums\OrderStatus;
use App\Enums\PaymentMethod;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Models\Order;
use App\Services\OrderStatusService;
use App\Services\Payments\PaymentService;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Enums\FiltersLayout;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\Indicator;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class OrdersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('order_ref')
                    ->label('Ref')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('user.name')
                    ->label('Customer')
                    ->searchable()
                    ->toggleable(),
                TextColumn::make('sandType.name')
                    ->label('Sand')
                    ->toggleable(),
                TextColumn::make('truckType.name')
                    ->label('Truck')
                    ->toggleable(),
                TextColumn::make('total_ghs')
                    ->label('Total (GHS)')
                    ->numeric(decimalPlaces: 2)
                    ->sortable(),
                TextColumn::make('region')
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('city')
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (OrderStatus $state): string => $state->label())
                    ->color(fn (OrderStatus $state): string => match ($state) {
                        OrderStatus::Confirmed => 'warning',
                        OrderStatus::OnTheWay => 'info',
                        OrderStatus::Delivered => 'success',
                        OrderStatus::Cancelled => 'danger',
                    }),
                TextColumn::make('payment_status')
                    ->label('Payment')
                    ->badge()
                    ->formatStateUsing(fn (PaymentStatus $state): string => ucfirst($state->value))
                    ->color(fn (PaymentStatus $state): string => match ($state) {
                        PaymentStatus::Paid => 'success',
                        PaymentStatus::Pending => 'warning',
                        PaymentStatus::Failed => 'danger',
                    }),
                TextColumn::make('assignedOperator.name')
                    ->label('Operator')
                    ->placeholder('Unassigned')
                    ->toggleable(),
                TextColumn::make('created_at')
                    ->label('Placed')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Status')
                    ->multiple()
                    ->options(collect(OrderStatus::cases())->mapWithKeys(
                        fn (OrderStatus $status) => [$status->value => $status->label()],
                    )),
                SelectFilter::make('payment_status')
                    ->label('Payment status')
                    ->options(collect(PaymentStatus::cases())->mapWithKeys(
                        fn (PaymentStatus $status) => [$status->value => ucfirst($status->value)],
                    )),
                SelectFilter::make('payment_method')
                    ->label('Payment method')
                    ->options([
                        PaymentMethod::Momo->value => 'Mobile Money',
                        PaymentMethod::Cod->value => 'Cash on delivery',
                    ]),
                SelectFilter::make('sand_type_id')
                    ->label('Sand')
                    ->relationship('sandType', 'name')
                    ->preload()
                    ->searchable(),
                SelectFilter::make('truck_type_id')
                    ->label('Truck')
                    ->relationship('truckType', 'name')
                    ->preload()
                    ->searchable(),
                SelectFilter::make('region')
                    ->label('Region')
                    ->searchable()
                    ->options(collect(config('ghana.regions'))->mapWithKeys(
                        fn (string $region) => [$region => $region],
                    )),
                SelectFilter::make('assigned_operator_id')
                    ->label('Operator')
                    ->relationship(
                        'assignedOperator',
                        'name',
                        fn (Builder $query): Builder => $query->where('role', UserRole::Operator),
                        hasEmptyOption: true,
                    )
                    ->preload()
                    ->searchable(),
                Filter::make('placed_from')
                    ->label('Placed from')
                    ->schema([
                        DatePicker::make('value')
                            ->label('Placed from')
                            ->native(false),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query->when(
                            filled($data['value'] ?? null),
                            fn (Builder $q): Builder => $q->whereDate('created_at', '>=', $data['value']),
                        );
                    })
                    ->indicateUsing(function (array $data): array {
                        if (blank($data['value'] ?? null)) {
                            return [];
                        }

                        return [Indicator::make('From '.$data['value'])->removeField('value')];
                    }),
                Filter::make('placed_until')
                    ->label('Placed until')
                    ->schema([
                        DatePicker::make('value')
                            ->label('Placed until')
                            ->native(false),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query->when(
                            filled($data['value'] ?? null),
                            fn (Builder $q): Builder => $q->whereDate('created_at', '<=', $data['value']),
                        );
                    })
                    ->indicateUsing(function (array $data): array {
                        if (blank($data['value'] ?? null)) {
                            return [];
                        }

                        return [Indicator::make('Until '.$data['value'])->removeField('value')];
                    }),
            ], layout: FiltersLayout::AboveContent)
            ->filtersFormColumns([
                'default' => 1,
                'sm' => 2,
                'lg' => 3,
            ])
            ->deferFilters(false)
            ->recordActions([
                ViewAction::make(),
                EditAction::make()
                    ->visible(fn (): bool => Auth::user()?->role === UserRole::Admin),
                self::dispatchAction(),
                self::deliverAction(),
                self::markPaidAction(),
                self::cancelAction(),
            ])
            ->toolbarActions([]);
    }

    private static function canMutate(Order $record): bool
    {
        $user = Auth::user();

        if ($user?->role === UserRole::Admin) {
            return true;
        }

        return $user?->role === UserRole::Operator
            && (int) $record->assigned_operator_id === (int) $user->id;
    }

    private static function runTransition(Order $record, OrderStatus $to, string $note): void
    {
        try {
            app(OrderStatusService::class)->transition($record, $to, Auth::user(), $note);
            Notification::make()
                ->title('Status updated')
                ->body("Order marked as {$to->label()}.")
                ->success()
                ->send();
        } catch (ValidationException $e) {
            Notification::make()
                ->title('Transition blocked')
                ->body(collect($e->errors())->flatten()->first() ?? 'Illegal status change.')
                ->danger()
                ->send();
        }
    }

    private static function dispatchAction(): Action
    {
        return Action::make('dispatch')
            ->label('Mark On The Way')
            ->icon('heroicon-o-truck')
            ->color('info')
            ->requiresConfirmation()
            ->visible(fn (Order $record): bool => $record->status === OrderStatus::Confirmed
                && self::canMutate($record))
            ->action(fn (Order $record) => self::runTransition(
                $record,
                OrderStatus::OnTheWay,
                'Marked on the way from admin panel',
            ));
    }

    private static function deliverAction(): Action
    {
        return Action::make('deliver')
            ->label('Mark Delivered')
            ->icon('heroicon-o-check-badge')
            ->color('success')
            ->requiresConfirmation()
            ->visible(fn (Order $record): bool => $record->status === OrderStatus::OnTheWay
                && self::canMutate($record))
            ->action(fn (Order $record) => self::runTransition(
                $record,
                OrderStatus::Delivered,
                'Marked delivered from admin panel',
            ));
    }

    private static function markPaidAction(): Action
    {
        return Action::make('markPaid')
            ->label('Mark Paid')
            ->icon('heroicon-o-banknotes')
            ->color('success')
            ->button()
            ->requiresConfirmation()
            ->modalHeading('Mark payment as paid?')
            ->modalDescription('Use this for COD collected early or a payment that cleared outside the app.')
            ->visible(fn (Order $record): bool => Auth::user()?->role === UserRole::Admin
                && $record->payment_status === PaymentStatus::Pending)
            ->action(function (Order $record): void {
                try {
                    app(PaymentService::class)->markPaid($record);
                    Notification::make()
                        ->title('Payment updated')
                        ->body('Order marked as paid.')
                        ->success()
                        ->send();
                } catch (ValidationException $e) {
                    Notification::make()
                        ->title('Could not mark paid')
                        ->body(collect($e->errors())->flatten()->first() ?? 'Update failed.')
                        ->danger()
                        ->send();
                }
            });
    }

    private static function cancelAction(): Action
    {
        return Action::make('cancel')
            ->label('Cancel')
            ->icon('heroicon-o-x-circle')
            ->color('danger')
            ->requiresConfirmation()
            ->form([
                Textarea::make('note')
                    ->label('Cancellation note')
                    ->rows(3),
            ])
            ->visible(fn (Order $record): bool => Auth::user()?->role === UserRole::Admin
                && in_array($record->status, [OrderStatus::Confirmed, OrderStatus::OnTheWay], true))
            ->action(function (Order $record, array $data): void {
                self::runTransition(
                    $record,
                    OrderStatus::Cancelled,
                    $data['note'] ?: 'Cancelled from admin panel',
                );
            });
    }
}
