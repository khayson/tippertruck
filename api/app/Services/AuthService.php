<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    // Valid bcrypt cost-12 hash used when no user matches the email.
    // Hash::check runs real bcrypt rounds against it, so the missing-user
    // path costs the same ~200ms as a wrong-password path and an attacker
    // cannot distinguish the two by timing. This MUST remain a valid
    // 60-char bcrypt hash — a malformed string is rejected on the format
    // check without running any rounds, silently disabling the protection.
    public const DUMMY_HASH = '$2y$12$Ap4cmToJSegd/eu.bS2oouCyZsB9pDcVeY7wEWHLsOIY.gB69Iuym';

    public function register(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['phone'] ?? null,
            'role' => UserRole::Client,
        ]);

        $token = $user->createToken('auth')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }

    public function attempt(string $email, string $password): ?array
    {
        $user = User::where('email', $email)->first();

        if (! $user) {
            Hash::check($password, self::DUMMY_HASH);

            return null;
        }

        if (! Hash::check($password, $user->password)) {
            return null;
        }

        $token = $user->createToken('auth')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }
}
