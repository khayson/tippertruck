<?php

declare(strict_types=1);

namespace App\Models;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use Database\Factories\IssueFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Issue extends Model
{
    /** @use HasFactory<IssueFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id',
        'order_id',
        'issue_type',
        'description',
        'status',
        'admin_response',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'issue_type' => IssueType::class,
            'status' => IssueStatus::class,
            'resolved_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
