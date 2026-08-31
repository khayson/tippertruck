<?php

declare(strict_types=1);

namespace App\Filament\Concerns;

use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

trait AdminOnlyResource
{
    public static function canViewAny(): bool
    {
        return Auth::user()?->role === UserRole::Admin;
    }

    public static function canCreate(): bool
    {
        return Auth::user()?->role === UserRole::Admin;
    }

    public static function canEdit(Model $record): bool
    {
        return Auth::user()?->role === UserRole::Admin;
    }

    public static function canDelete(Model $record): bool
    {
        return Auth::user()?->role === UserRole::Admin;
    }

    public static function canDeleteAny(): bool
    {
        return Auth::user()?->role === UserRole::Admin;
    }
}
