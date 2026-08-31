<?php

declare(strict_types=1);

use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Filament\Resources\Issues\IssueResource;
use App\Filament\Resources\Orders\OrderResource;
use App\Filament\Resources\Orders\Pages\ListOrders;
use App\Filament\Resources\Users\UserResource;
use App\Filament\Widgets\OrdersStatsOverview;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderStatusService;
use Livewire\Livewire;

use function Pest\Laravel\actingAs;
use function Pest\Laravel\assertDatabaseHas;
use function Pest\Laravel\get;

beforeEach(function (): void {
    $this->admin = User::factory()->create(['role' => UserRole::Admin]);
    $this->operator = User::factory()->create(['role' => UserRole::Operator]);
    $this->client = User::factory()->create(['role' => UserRole::Client]);
});

it('allows admin to open the filament panel', function (): void {
    actingAs($this->admin);

    get('/admin')->assertOk();
});

it('blocks clients from the filament panel', function (): void {
    actingAs($this->client);

    get('/admin')->assertForbidden();
});

it('lets admin access orders users and issues resources', function (): void {
    actingAs($this->admin);

    expect(OrderResource::canViewAny())->toBeTrue()
        ->and(UserResource::canViewAny())->toBeTrue()
        ->and(IssueResource::canViewAny())->toBeTrue();
});

it('scopes operator order list and hides admin-only resources', function (): void {
    actingAs($this->operator);

    expect(OrderResource::canViewAny())->toBeTrue()
        ->and(UserResource::canViewAny())->toBeFalse()
        ->and(IssueResource::canViewAny())->toBeFalse();

    $mine = Order::factory()->create([
        'assigned_operator_id' => $this->operator->id,
        'status' => OrderStatus::Confirmed,
    ]);
    $theirs = Order::factory()->create([
        'assigned_operator_id' => null,
        'status' => OrderStatus::Confirmed,
    ]);

    $ids = OrderResource::getEloquentQuery()->pluck('id');

    expect($ids)->toContain($mine->id)
        ->and($ids)->not->toContain($theirs->id);
});

it('transitions order status through OrderStatusService from the panel path', function (): void {
    $order = Order::factory()->create([
        'assigned_operator_id' => $this->operator->id,
        'status' => OrderStatus::Confirmed,
    ]);

    app(OrderStatusService::class)->transition(
        $order,
        OrderStatus::OnTheWay,
        $this->admin,
        'Marked on the way from admin panel',
    );

    assertDatabaseHas('orders', [
        'id' => $order->id,
        'status' => OrderStatus::OnTheWay->value,
    ]);

    assertDatabaseHas('order_status_log', [
        'order_id' => $order->id,
        'old_status' => OrderStatus::Confirmed->value,
        'new_status' => OrderStatus::OnTheWay->value,
        'changed_by' => $this->admin->id,
    ]);
});

it('renders dashboard stats widget for admin', function (): void {
    actingAs($this->admin);

    Livewire::test(OrdersStatsOverview::class)
        ->assertSuccessful();
});

it('renders the orders list for an admin', function (): void {
    actingAs($this->admin);
    Order::factory()->count(2)->create();

    Livewire::test(ListOrders::class)
        ->assertSuccessful();
});
