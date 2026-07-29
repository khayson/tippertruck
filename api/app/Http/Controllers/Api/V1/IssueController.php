<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Enums\IssueStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreIssueRequest;
use App\Http\Resources\IssueResource;
use App\Http\Traits\ApiResponse;
use App\Models\Issue;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IssueController extends Controller
{
    use ApiResponse;

    public function store(StoreIssueRequest $request): JsonResponse
    {
        $issue = Issue::create([
            'user_id' => $request->user()->id,
            'order_id' => $request->validated('order_id'),
            'issue_type' => $request->validated('issue_type'),
            'description' => $request->validated('description'),
            'status' => IssueStatus::Open,
        ]);

        $issue->load('order');

        return $this->success(
            ['issue' => new IssueResource($issue)],
            'Issue reported.',
            201,
        );
    }

    public function index(Request $request): JsonResponse
    {
        $issues = $request->user()->issues()
            ->with('order:id,order_ref')
            ->latest()
            ->paginate(15);

        return $this->success([
            'issues' => IssueResource::collection($issues->items()),
            'meta' => [
                'current_page' => $issues->currentPage(),
                'last_page' => $issues->lastPage(),
                'per_page' => $issues->perPage(),
                'total' => $issues->total(),
            ],
        ]);
    }
}
