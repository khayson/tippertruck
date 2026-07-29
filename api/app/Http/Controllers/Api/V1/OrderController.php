<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Enums\OrderStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreOrderRequest;
use App\Http\Resources\OrderResource;
use App\Http\Traits\ApiResponse;
use App\Models\Order;
use App\Services\OrderService;
use App\Services\OrderStatusService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly OrderService $orderService,
        private readonly OrderStatusService $statusService,
    ) {}

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->orderService->create($request->validated(), $request->user());

        return $this->success(
            ['order' => new OrderResource($order)],
            'Order created.',
            201,
        );
    }

    public function index(Request $request): JsonResponse
    {
        $query = $request->user()->orders()
            ->with(['sandType', 'truckType'])
            ->latest();

        if ($request->has('status')) {
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
        if ($request->user()->cannot('view', $order)) {
            return $this->error('Forbidden.', 403);
        }

        $order->load(['sandType', 'truckType', 'statusLogs']);

        return $this->success(['order' => new OrderResource($order)]);
    }

    public function cancel(Request $request, Order $order): JsonResponse
    {
        if ($request->user()->cannot('cancel', $order)) {
            return $this->error('You cannot cancel this order.', 403);
        }

        $order = $this->statusService->transition(
            $order,
            OrderStatus::Cancelled,
            $request->user(),
            'Cancelled by '.$request->user()->role->value,
        );

        $order->load(['sandType', 'truckType', 'statusLogs']);

        return $this->success(
            ['order' => new OrderResource($order)],
            'Order cancelled.',
        );
    }
}
