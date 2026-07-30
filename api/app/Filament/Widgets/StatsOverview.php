<?php

declare(strict_types=1);

namespace App\Filament\Widgets;

use App\Enums\IssueStatus;
use App\Enums\OrderStatus;
use App\Models\Issue;
use App\Models\Order;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return [
            Stat::make('Orders Today', Order::whereDate('created_at', today())->count()),
            Stat::make('Orders This Week', Order::whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])->count()),
            Stat::make('Revenue This Month (GHS)', number_format(
                (float) Order::whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->where('status', '!=', OrderStatus::Cancelled)
                    ->sum('total_ghs'),
                2,
            )),
            Stat::make('Open Issues', Issue::where('status', IssueStatus::Open)->count()),
        ];
    }
}
