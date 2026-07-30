<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Enums\MomoNetwork;
use App\Enums\PaymentMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $isMomo = $this->input('payment_method') === 'momo';

        return [
            'sand_type_id' => ['required', 'integer', Rule::exists('sand_types', 'id')->where('is_active', true)],
            'truck_type_id' => ['required', 'integer', Rule::exists('truck_types', 'id')->where('is_active', true)],
            'recipient_name' => ['required', 'string', 'max:255'],
            'recipient_phone' => ['required', 'string', 'regex:/^0\d{9}$/'],
            'street_address' => ['required', 'string', 'max:255'],
            'region' => ['required', 'string', Rule::exists('delivery_zones', 'region')->where('is_active', true)],
            'city' => ['required', 'string', 'max:255'],
            'landmark' => ['nullable', 'string', 'max:255'],
            'delivery_note' => ['nullable', 'string', 'max:1000'],
            'payment_method' => ['required', Rule::enum(PaymentMethod::class)],
            'momo_name' => [$isMomo ? 'required' : 'prohibited', 'string', 'max:255'],
            'momo_phone' => [$isMomo ? 'required' : 'prohibited', 'string', 'regex:/^0\d{9}$/'],
            'momo_network' => [$isMomo ? 'required' : 'prohibited', Rule::enum(MomoNetwork::class)],
            'pin' => ['prohibited'],
            'price_ghs' => ['prohibited'],
            'delivery_fee_ghs' => ['prohibited'],
            'total_ghs' => ['prohibited'],
        ];
    }

    public function messages(): array
    {
        return [
            'recipient_phone.regex' => 'Phone number must be 10 digits and start with 0.',
            'momo_phone.regex' => 'MoMo phone number must be 10 digits and start with 0.',
            'pin.prohibited' => 'PIN must never be sent.',
            'price_ghs.prohibited' => 'Price is determined server-side.',
            'total_ghs.prohibited' => 'Total is determined server-side.',
            'region.exists' => 'We do not currently deliver to this region.',
        ];
    }
}
