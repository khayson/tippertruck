<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Enums\SocialProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Requests\Api\V1\SocialLoginRequest;
use App\Http\Resources\UserResource;
use App\Http\Traits\ApiResponse;
use App\Services\AuthService;
use App\Services\SocialAuth\InvalidSocialTokenException;
use App\Services\SocialAuth\SocialAuthManager;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AuthService $authService,
        private readonly SocialAuthManager $socialAuth,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());

        return $this->success([
            'user' => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'Registration successful.', 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->attempt(
            $request->validated('email'),
            $request->validated('password'),
        );

        if (! $result) {
            return $this->error('Invalid credentials.', 401);
        }

        return $this->success([
            'user' => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'Login successful.');
    }

    public function social(SocialLoginRequest $request): JsonResponse
    {
        $provider = SocialProvider::from($request->validated('provider'));

        try {
            $socialUser = $this->socialAuth->verify(
                $provider,
                $request->validated('id_token'),
            );
        } catch (InvalidSocialTokenException $e) {
            return $this->error($e->getMessage(), 401);
        }

        $result = $this->authService->loginWithSocial($socialUser);

        return $this->success([
            'user' => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'Login successful.');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(message: 'Logged out.');
    }

    public function me(Request $request): JsonResponse
    {
        return $this->success([
            'user' => new UserResource($request->user()),
        ]);
    }
}
