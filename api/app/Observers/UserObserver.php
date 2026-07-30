<?php

declare(strict_types=1);

namespace App\Observers;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class UserObserver
{
    public function updating(User $user): void
    {
        if (! $user->isDirty('role')) {
            return;
        }

        if ($user->getOriginal('role') !== UserRole::Admin) {
            return;
        }

        if ($user->role === UserRole::Admin) {
            return;
        }

        if ($user->id === auth()->id()) {
            throw ValidationException::withMessages([
                'data.role' => ['You cannot demote your own admin account.'],
            ]);
        }

        $otherAdmins = User::where('id', '!=', $user->id)
            ->where('role', UserRole::Admin)
            ->exists();

        if (! $otherAdmins) {
            throw ValidationException::withMessages([
                'data.role' => ['Cannot remove the last admin account.'],
            ]);
        }
    }

    public function deleting(User $user): void
    {
        if ($user->role !== UserRole::Admin) {
            return;
        }

        $otherAdmins = User::where('id', '!=', $user->id)
            ->where('role', UserRole::Admin)
            ->exists();

        if (! $otherAdmins) {
            throw ValidationException::withMessages([
                'data.role' => ['Cannot delete the last admin account.'],
            ]);
        }
    }
}
