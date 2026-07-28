<?php

declare(strict_types=1);

namespace App\Enums;

enum IssueStatus: string
{
    case Open = 'open';
    case InReview = 'in_review';
    case Resolved = 'resolved';
    case Closed = 'closed';
}
