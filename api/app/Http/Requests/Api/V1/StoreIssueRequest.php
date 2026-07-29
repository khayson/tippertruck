<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Enums\IssueType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreIssueRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'issue_type' => ['required', Rule::enum(IssueType::class)],
            'description' => ['required', 'string', 'min:10', 'max:5000'],
            'order_id' => [
                'sometimes',
                'nullable',
                'integer',
                Rule::exists('orders', 'id')->where('user_id', $this->user()->id),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'order_id.exists' => 'The selected order does not exist or does not belong to you.',
        ];
    }
}
