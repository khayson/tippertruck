<?php

declare(strict_types=1);

use App\Enums\IssueStatus;
use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Filament\Resources\DeliveryZoneResource;
use App\Filament\Resources\IssueResource;
use App\Filament\Resources\OrderResource;
use App\Filament\Resources\SandTruckPriceResource;
use App\Filament\Resources\SandTypeResource;
use App\Filament\Resources\TruckTypeResource;
use App\Filament\Resources\UserResource;
use App\Models\DeliveryZone;
use App\Models\Issue;
use App\Models\Order;
use App\Models\OrderStatusLog;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->seed();
});

// --- Operator cannot reach admin-only resources ---

test('operator cannot reach users resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(UserResource::getUrl('index'))
        ->assertStatus(403);
});

test('operator cannot reach issues resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(IssueResource::getUrl('index'))
        ->assertStatus(403);
});

test('operator cannot reach sand type resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(SandTypeResource::getUrl('index'))
        ->assertStatus(403);
});

test('operator cannot reach truck type resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(TruckTypeResource::getUrl('index'))
        ->assertStatus(403);
});

test('operator cannot reach price matrix resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(SandTruckPriceResource::getUrl('index'))
        ->assertStatus(403);
});

test('operator cannot reach delivery zone resource by URL', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $this->actingAs($operator)
        ->get(DeliveryZoneResource::getUrl('index'))
        ->assertStatus(403);
});

// --- Operator sees only assigned orders ---

test('operator sees only their assigned orders', function () {
    $operator = User::where('role', UserRole::Operator)->first();

    $assignedCount = Order::where('assigned_operator_id', $operator->id)->count();
    $totalCount = Order::count();

    expect($assignedCount)->toBeGreaterThan(0)
        ->and($assignedCount)->toBeLessThan($totalCount);

    $this->actingAs($operator);

    $query = OrderResource::getEloquentQuery();
    $visibleCount = $query->count();

    expect($visibleCount)->toBe($assignedCount);
});

// --- Admin sees all orders ---

test('admin sees all orders', function () {
    $admin = User::where('role', UserRole::Admin)->first();

    $this->actingAs($admin);

    $query = OrderResource::getEloquentQuery();
    expect($query->count())->toBe(Order::count());
});

// --- Status actions perform transitions and write log rows ---

test('mark on the way action transitions a confirmed order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::Confirmed)->first();
    $logCountBefore = OrderStatusLog::where('order_id', $order->id)->count();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->callTableAction('mark_on_the_way', $order);

    $order->refresh();
    expect($order->status)->toBe(OrderStatus::OnTheWay)
        ->and($order->dispatched_at)->not->toBeNull();

    $logCountAfter = OrderStatusLog::where('order_id', $order->id)->count();
    expect($logCountAfter)->toBe($logCountBefore + 1);
});

test('mark delivered action transitions an on_the_way order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::OnTheWay)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->callTableAction('mark_delivered', $order);

    $order->refresh();
    expect($order->status)->toBe(OrderStatus::Delivered)
        ->and($order->delivered_at)->not->toBeNull();
});

test('cancel action transitions a confirmed order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::Confirmed)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->callTableAction('cancel', $order);

    $order->refresh();
    expect($order->status)->toBe(OrderStatus::Cancelled);
});

// --- Illegal action is not rendered ---

test('mark on the way action is not visible for delivered order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::Delivered)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->assertTableActionHidden('mark_on_the_way', $order);
});

test('mark delivered action is not visible for confirmed order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::Confirmed)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->assertTableActionHidden('mark_delivered', $order);
});

test('cancel action is not visible for delivered order', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $order = Order::where('status', OrderStatus::Delivered)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(OrderResource\Pages\ListOrders::class)
        ->assertTableActionHidden('cancel', $order);
});

// --- Admin cannot demote themselves ---

test('admin cannot demote their own account', function () {
    $admin = User::where('role', UserRole::Admin)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(UserResource\Pages\EditUser::class, ['record' => $admin->id])
        ->fillForm(['role' => UserRole::Client->value])
        ->call('save')
        ->assertHasFormErrors(['role']);

    $admin->refresh();
    expect($admin->role)->toBe(UserRole::Admin);
});

// --- Last active delivery zone cannot be deactivated ---

test('last active delivery zone cannot be deactivated', function () {
    $admin = User::where('role', UserRole::Admin)->first();

    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);

    $lastZone = DeliveryZone::where('is_active', true)->sole();

    $this->actingAs($admin);

    Livewire\Livewire::test(DeliveryZoneResource\Pages\EditDeliveryZone::class, ['record' => $lastZone->id])
        ->fillForm(['is_active' => false])
        ->call('save')
        ->assertHasFormErrors(['is_active']);

    $lastZone->refresh();
    expect($lastZone->is_active)->toBeTrue();
});

// --- Issue resolve action ---

test('resolve action sets status and resolved_at', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $issue = Issue::where('status', IssueStatus::Open)->first();

    $this->actingAs($admin);

    Livewire\Livewire::test(IssueResource\Pages\ListIssues::class)
        ->callTableAction('resolve', $issue, data: [
            'admin_response' => 'We have resolved your issue.',
        ]);

    $issue->refresh();
    expect($issue->status)->toBe(IssueStatus::Resolved)
        ->and($issue->admin_response)->toBe('We have resolved your issue.')
        ->and($issue->resolved_at)->not->toBeNull();
});

// --- Client cannot access panel ---

test('client cannot access admin panel', function () {
    $client = User::where('role', UserRole::Client)->first();

    $this->actingAs($client)
        ->get('/admin')
        ->assertForbidden();
});

// --- Observer guards: attack the bypass ---

test('observer blocks last admin demotion even via raw update', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    expect(User::where('role', UserRole::Admin)->count())->toBe(1);

    expect(fn () => $admin->update(['role' => UserRole::Client]))
        ->toThrow(ValidationException::class);

    $admin->refresh();
    expect($admin->role)->toBe(UserRole::Admin);
});

test('observer blocks last admin deletion even via raw delete', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    expect(User::where('role', UserRole::Admin)->count())->toBe(1);

    expect(fn () => $admin->delete())
        ->toThrow(ValidationException::class);

    expect(User::where('id', $admin->id)->exists())->toBeTrue();
});

test('observer blocks self-demotion even via raw update', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $secondAdmin = User::factory()->create(['role' => UserRole::Admin]);

    $this->actingAs($admin);

    expect(fn () => $admin->update(['role' => UserRole::Operator]))
        ->toThrow(ValidationException::class);

    $admin->refresh();
    expect($admin->role)->toBe(UserRole::Admin);
});

test('observer allows demoting a non-last admin by another admin', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $secondAdmin = User::factory()->create(['role' => UserRole::Admin]);

    $this->actingAs($admin);

    $secondAdmin->update(['role' => UserRole::Operator]);

    $secondAdmin->refresh();
    expect($secondAdmin->role)->toBe(UserRole::Operator);
});

test('observer blocks deactivating the last active delivery zone via raw update', function () {
    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);
    $lastZone = DeliveryZone::where('is_active', true)->sole();

    expect(fn () => $lastZone->update(['is_active' => false]))
        ->toThrow(ValidationException::class);

    $lastZone->refresh();
    expect($lastZone->is_active)->toBeTrue();
});

test('observer blocks deleting the last active delivery zone', function () {
    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);
    $lastZone = DeliveryZone::where('is_active', true)->sole();

    expect(fn () => $lastZone->delete())
        ->toThrow(ValidationException::class);

    expect(DeliveryZone::where('id', $lastZone->id)->exists())->toBeTrue();
});

test('observer allows deleting an inactive delivery zone', function () {
    DeliveryZone::where('region', 'Central')->update(['is_active' => false]);
    $inactive = DeliveryZone::where('is_active', false)->first();

    $inactive->delete();

    expect(DeliveryZone::where('id', $inactive->id)->exists())->toBeFalse();
});

// --- RESTRICT violations handled gracefully ---

test('deleting a referenced sand type shows notification and leaves row intact', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $sandType = Order::first()->sandType;

    $this->actingAs($admin);

    Livewire\Livewire::test(SandTypeResource\Pages\EditSandType::class, ['record' => $sandType->id])
        ->callAction('delete');

    expect(SandType::where('id', $sandType->id)->exists())->toBeTrue();
});

test('deleting a referenced truck type shows notification and leaves row intact', function () {
    $admin = User::where('role', UserRole::Admin)->first();
    $truckType = Order::first()->truckType;

    $this->actingAs($admin);

    Livewire\Livewire::test(TruckTypeResource\Pages\EditTruckType::class, ['record' => $truckType->id])
        ->callAction('delete');

    expect(TruckType::where('id', $truckType->id)->exists())->toBeTrue();
});
