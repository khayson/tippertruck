<?php

declare(strict_types=1);

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;

class OrdersChart extends ChartWidget
{
    protected ?string $heading = 'Orders (Last 14 Days)';

    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $days = collect(range(13, 0))->map(fn (int $i) => now()->subDays($i)->format('Y-m-d'));

        $counts = Order::query()
            ->where('created_at', '>=', now()->subDays(14)->startOfDay())
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date');

        return [
            'datasets' => [
                [
                    'label' => 'Orders',
                    'data' => $days->map(fn (string $date) => $counts->get($date, 0))->values()->toArray(),
                ],
            ],
            'labels' => $days->map(fn (string $date) => Carbon::parse($date)->format('M d'))->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
