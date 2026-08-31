<?php

declare(strict_types=1);

namespace App\Filament\Resources\Orders\Pages;

use App\Enums\OrderStatus;
use App\Enums\PaymentStatus;
use App\Enums\UserRole;
use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use App\Services\OrderStatusService;
use App\Services\Payments\PaymentService;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class ViewOrder extends ViewRecord
{
    protected static string $resource = OrderResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->markPaidAction(),
            $this->dispatchAction(),
            $this->deliverAction(),
            $this->cancelAction(),
            EditAction::make()
                ->visible(fn (): bool => Auth::user()?->role === UserRole::Admin),
        ];
    }

    private function canMutate(): bool
    {
        /** @var Order $record */
        $record = $this->getRecord();
        $user = Auth::user();

        if ($user?->role === UserRole::Admin) {
            return true;
        }

        return $user?->role === UserRole::Operator
            && (int) $record->assigned_operator_id === (int) $user->id;
    }

    private function runTransition(OrderStatus $to, string $note): void
    {
        try {
            app(OrderStatusService::class)->transition($this->getRecord(), $to, Auth::user(), $note);
            Notification::make()
                ->title('Status updated')
                ->body("Order marked as {$to->label()}.")
                ->success()
                ->send();
            $this->refreshFormData(['status', 'payment_status', 'dispatched_at', 'delivered_at']);
        } catch (ValidationException $e) {
            Notification::make()
                ->title('Transition blocked')
                ->body(collect($e->errors())->flatten()->first() ?? 'Illegal status change.')
                ->danger()
                ->send();
        }
    }

    private function markPaidAction(): Action
    {
        return Action::make('markPaid')
            ->label('Mark Paid')
            ->icon('heroicon-o-banknotes')
            ->color('success')
            ->requiresConfirmation()
            ->modalHeading('Mark payment as paid?')
            ->modalDescription('Use this for COD collected early or a payment that cleared outside the app.')
            ->visible(fn (): bool => Auth::user()?->role === UserRole::Admin
                && $this->getRecord()->payment_status === PaymentStatus::Pending)
            ->action(function (): void {
                try {
                    app(PaymentService::class)->markPaid($this->getRecord());
                    Notification::make()
                        ->title('Payment updated')
                        ->body('Order marked as paid.')
                        ->success()
                        ->send();
                    $this->refreshFormData(['payment_status']);
                } catch (ValidationException $e) {
                    Notification::make()
                        ->title('Could not mark paid')
                        ->body(collect($e->errors())->flatten()->first() ?? 'Update failed.')
                        ->danger()
                        ->send();
                }
            });
    }

    private function dispatchAction(): Action
    {
        return Action::make('dispatch')
            ->label('Mark On The Way')
            ->icon('heroicon-o-truck')
            ->color('info')
            ->requiresConfirmation()
            ->visible(fn (): bool => $this->getRecord()->status === OrderStatus::Confirmed
                && $this->canMutate())
            ->action(fn () => $this->runTransition(
                OrderStatus::OnTheWay,
                'Marked on the way from admin panel',
            ));
    }

    private function deliverAction(): Action
    {
        return Action::make('deliver')
            ->label('Mark Delivered')
            ->icon('heroicon-o-check-badge')
            ->color('success')
            ->requiresConfirmation()
            ->visible(fn (): bool => $this->getRecord()->status === OrderStatus::OnTheWay
                && $this->canMutate())
            ->action(fn () => $this->runTransition(
                OrderStatus::Delivered,
                'Marked delivered from admin panel',
            ));
    }

    private function cancelAction(): Action
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
            ->visible(fn (): bool => Auth::user()?->role === UserRole::Admin
                && in_array($this->getRecord()->status, [OrderStatus::Confirmed, OrderStatus::OnTheWay], true))
            ->action(function (array $data): void {
                $this->runTransition(
                    OrderStatus::Cancelled,
                    $data['note'] ?: 'Cancelled from admin panel',
                );
            });
    }
}
