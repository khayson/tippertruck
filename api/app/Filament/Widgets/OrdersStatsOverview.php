<?php

declare(strict_types=1);

namespace App\Filament\Widgets;

use App\Enums\IssueStatus;
use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Models\Issue;
use App\Models\Order;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Eloquent\Builder;

class OrdersStatsOverview extends StatsOverviewWidget
{
    protected ?string $pollingInterval = '30s';

    protected ?string $heading = 'Operations overview';

    protected function getStats(): array
    {
        /** @var User $user */
        $user = auth()->user();
        $isOperator = $user->role === UserRole::Operator;

        $orders = Order::query()
            ->when(
                $isOperator,
                fn (Builder $query): Builder => $query->where('assigned_operator_id', $user->id),
            );

        $confirmed = (clone $orders)->where('status', OrderStatus::Confirmed)->count();
        $onTheWay = (clone $orders)->where('status', OrderStatus::OnTheWay)->count();
        $deliveredToday = (clone $orders)
            ->where('status', OrderStatus::Delivered)
            ->whereDate('delivered_at', today())
            ->count();
        $total = (clone $orders)->count();

        $stats = [
            Stat::make('Confirmed', (string) $confirmed)
                ->description($isOperator ? 'Assigned to you' : 'Awaiting dispatch')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),
            Stat::make('On the way', (string) $onTheWay)
                ->description('In transit')
                ->descriptionIcon('heroicon-m-truck')
                ->color('info'),
            Stat::make('Delivered today', (string) $deliveredToday)
                ->description('Completed today')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),
            Stat::make('All orders', (string) $total)
                ->description($isOperator ? 'Your assignments' : 'All time')
                ->descriptionIcon('heroicon-m-clipboard-document-list')
                ->color('gray'),
        ];

        if (! $isOperator) {
            $openIssues = Issue::query()
                ->whereIn('status', [IssueStatus::Open, IssueStatus::InReview])
                ->count();

            $stats[] = Stat::make('Open issues', (string) $openIssues)
                ->description('Needs attention')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color($openIssues > 0 ? 'danger' : 'success');
        }

        return $stats;
    }
}
