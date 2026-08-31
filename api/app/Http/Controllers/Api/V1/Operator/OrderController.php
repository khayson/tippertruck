<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Operator;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\IndexOrderRequest;
use App\Http\Resources\OrderResource;
use App\Http\Traits\ApiResponse;
use App\Models\Order;
use App\Services\OrderStatusService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly OrderStatusService $statusService) {}

    public function index(IndexOrderRequest $request): JsonResponse
    {
        $query = Order::query()
            ->where('assigned_operator_id', $request->user()->id)
            ->with(['sandType', 'truckType'])
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $orders = $query->paginate(15);

        return $this->success([
            'orders' => OrderResource::collection($orders->items()),
            'meta' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'per_page' => $orders->perPage(),
                'total' => $orders->total(),
            ],
        ]);
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->cannot('viewAsOperator', $order)) {
            return $this->error('Forbidden.', 403);
        }

        $order->load(['sandType', 'truckType', 'statusLogs']);

        return $this->success(['order' => new OrderResource($order)]);
    }

    public function dispatch(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->cannot('dispatch', $order)) {
            return $this->error('Forbidden.', 403);
        }

        $order = $this->statusService->transition(
            $order,
            OrderStatus::OnTheWay,
            $request->user(),
            'Dispatched by operator',
        );

        $order->load(['sandType', 'truckType', 'statusLogs']);

        return $this->success(
            ['order' => new OrderResource($order)],
            'Order marked on the way.',
        );
    }

    public function deliver(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->cannot('deliver', $order)) {
            return $this->error('Forbidden.', 403);
        }

        $order = $this->statusService->transition(
            $order,
            OrderStatus::Delivered,
            $request->user(),
            'Delivered by operator',
        );

        $order->load(['sandType', 'truckType', 'statusLogs']);

        return $this->success(
            ['order' => new OrderResource($order)],
            'Order marked delivered.',
        );
    }
}
