<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Enums\SocialProvider;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class SocialLoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'provider' => ['required', 'string', Rule::enum(SocialProvider::class)],
            'id_token' => ['required', 'string', 'min:10'],
        ];
    }
}
