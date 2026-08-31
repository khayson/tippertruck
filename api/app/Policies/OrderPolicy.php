<?php

declare(strict_types=1);

namespace App\Policies;

use App\Enums\OrderStatus;
use App\Enums\UserRole;
use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->user_id
            || $user->role === UserRole::Admin
            || ($user->role === UserRole::Operator && $order->assigned_operator_id === $user->id);
    }

    public function viewAsOperator(User $user, Order $order): bool
    {
        return $user->role === UserRole::Operator
            && $order->assigned_operator_id === $user->id;
    }

    public function dispatch(User $user, Order $order): bool
    {
        return $this->viewAsOperator($user, $order)
            && $order->status === OrderStatus::Confirmed;
    }

    public function deliver(User $user, Order $order): bool
    {
        return $this->viewAsOperator($user, $order)
            && $order->status === OrderStatus::OnTheWay;
    }

    public function cancel(User $user, Order $order): bool
    {
        if ($user->role === UserRole::Admin) {
            return in_array($order->status, [OrderStatus::Confirmed, OrderStatus::OnTheWay], true);
        }

        if ($user->role === UserRole::Operator && $order->assigned_operator_id === $user->id) {
            return in_array($order->status, [OrderStatus::Confirmed, OrderStatus::OnTheWay], true);
        }

        return $user->id === $order->user_id && $order->status === OrderStatus::Confirmed;
    }
}
