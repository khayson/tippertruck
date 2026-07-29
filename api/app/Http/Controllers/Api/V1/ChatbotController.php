<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ChatbotMessageRequest;
use App\Http\Traits\ApiResponse;
use App\Services\ChatbotService;
use Illuminate\Http\JsonResponse;

class ChatbotController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly ChatbotService $chatbotService,
    ) {}

    public function message(ChatbotMessageRequest $request): JsonResponse
    {
        $result = $this->chatbotService->respond($request->validated('message'));

        return $this->success($result);
    }
}
