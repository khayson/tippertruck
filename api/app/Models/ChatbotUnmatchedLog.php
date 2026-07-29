<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatbotUnmatchedLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'message',
        'top_intent',
        'confidence',
    ];

    protected function casts(): array
    {
        return [
            'confidence' => 'decimal:2',
            'created_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
