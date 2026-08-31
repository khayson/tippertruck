<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders\Schemas;

use App\Enums\OrderStatus;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OrderInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Order')
                    ->columns(2)
                    ->components([
                        TextEntry::make('order_ref')->label('Reference'),
                        TextEntry::make('status')
                            ->badge()
                            ->formatStateUsing(fn (OrderStatus $state): string => $state->label())
                            ->color(fn (OrderStatus $state): string => match ($state) {
                                OrderStatus::Confirmed => 'warning',
                                OrderStatus::OnTheWay => 'info',
                                OrderStatus::Delivered => 'success',
                                OrderStatus::Cancelled => 'danger',
                            }),
                        TextEntry::make('user.name')->label('Customer'),
                        TextEntry::make('assignedOperator.name')
                            ->label('Operator')
                            ->placeholder('Unassigned'),
                        TextEntry::make('sandType.name')->label('Sand'),
                        TextEntry::make('truckType.name')->label('Truck'),
                        TextEntry::make('price_ghs')->label('Base (GHS)'),
                        TextEntry::make('delivery_fee_ghs')->label('Fee (GHS)'),
                        TextEntry::make('total_ghs')->label('Total (GHS)'),
                        TextEntry::make('created_at')->dateTime(),
                    ]),
                Section::make('Delivery')
                    ->columns(2)
                    ->components([
                        TextEntry::make('recipient_name'),
                        TextEntry::make('recipient_phone'),
                        TextEntry::make('street_address')->columnSpanFull(),
                        TextEntry::make('region'),
                        TextEntry::make('city'),
                        TextEntry::make('landmark')->placeholder('—'),
                        TextEntry::make('delivery_note')
                            ->placeholder('—')
                            ->columnSpanFull(),
                    ]),
                Section::make('Payment')
                    ->columns(2)
                    ->components([
                        TextEntry::make('payment_method')->badge(),
                        TextEntry::make('payment_status')->badge(),
                        TextEntry::make('momo_name')->placeholder('—'),
                        TextEntry::make('momo_phone')->placeholder('—'),
                        TextEntry::make('momo_network')->badge()->placeholder('—'),
                    ]),
                Section::make('Timestamps')
                    ->columns(3)
                    ->components([
                        TextEntry::make('confirmed_at')->dateTime()->placeholder('—'),
                        TextEntry::make('dispatched_at')->dateTime()->placeholder('—'),
                        TextEntry::make('delivered_at')->dateTime()->placeholder('—'),
                    ]),
            ]);
    }
}
