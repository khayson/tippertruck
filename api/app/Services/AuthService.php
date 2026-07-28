<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    // Bcrypt hash of "dummy" — compared when no user is found so both
    // code paths spend the same time in bcrypt and an attacker cannot
    // distinguish "no such email" from "wrong password" by timing.
    private const DUMMY_HASH = '$2y$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

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
