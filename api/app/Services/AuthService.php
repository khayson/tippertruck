<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    public function register(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['phone'] ?? null,
        ])->fresh();

        $token = $user->createToken('auth')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }

    public function attempt(string $email, string $password): ?array
    {
        $user = User::where('email', $email)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            return null;
        }

        $token = $user->createToken('auth')->plainTextToken;

        return ['user' => $user, 'token' => $token];
    }
}
