<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\SandType;
use App\Models\TruckType;

class ChatbotService
{
    public function respond(string $message): array
    {
        $input = mb_strtolower(trim($message));
        $rules = $this->rules();

        foreach ($rules as $rule) {
            foreach ($rule['keywords'] as $keyword) {
                if (str_contains($input, $keyword)) {
                    return [
                        'reply' => $rule['reply'](),
                        'matched_rule' => $rule['name'],
                        'quick_replies' => $rule['quick_replies'],
                    ];
                }
            }
        }

        $fallback = $this->fallbackRule();

        return [
            'reply' => $fallback['reply'](),
            'matched_rule' => $fallback['name'],
            'quick_replies' => $fallback['quick_replies'],
        ];
    }

    private function truckTypes(): array
    {
        return TruckType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['name', 'capacity_label', 'price_ghs'])
            ->toArray();
    }

    private function sandTypes(): array
    {
        return SandType::where('is_active', true)
            ->orderBy('sort_order')
            ->get(['name', 'description'])
            ->toArray();
    }

    private function formatPriceList(): string
    {
        $trucks = $this->truckTypes();

        return implode("\n", array_map(
            fn (array $t) => "• {$t['name']}: GHS {$t['price_ghs']} ({$t['capacity_label']})",
            $trucks,
        ));
    }

    private function rules(): array
    {
        return [
            [
                'name' => 'greeting',
                'keywords' => ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'],
                'reply' => fn () => 'Hello! Welcome to Tipper Truck. I can help you with pricing, sand types, truck sizes, booking, payments, and more. What would you like to know?',
                'quick_replies' => $this->defaultQuickReplies(),
            ],
            [
                'name' => 'pricing',
                'keywords' => ['price', 'cost', 'how much', 'charge', 'fee', 'pricing'],
                'reply' => fn () => "Here are our current prices:\n".$this->formatPriceList(),
                'quick_replies' => [
                    ['label' => '🏗️ Sand types', 'message' => 'What sand types do you have?'],
                    ['label' => '🚛 Truck sizes', 'message' => 'What truck sizes are available?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                ],
            ],
            [
                'name' => 'sand_types',
                'keywords' => ['sand type', 'kind of sand', 'types of sand', 'which sand', 'what sand'],
                'reply' => function () {
                    $types = $this->sandTypes();
                    $list = implode("\n", array_map(
                        fn (array $t) => "• {$t['name']}: {$t['description']}",
                        $types,
                    ));

                    return "We offer the following sand types:\n{$list}";
                },
                'quick_replies' => [
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                    ['label' => '🚛 Truck sizes', 'message' => 'What truck sizes are available?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                ],
            ],
            [
                'name' => 'truck_sizes',
                'keywords' => ['truck size', 'truck capacity', 'how big', 'tonnage', 'tonnes', 'tons'],
                'reply' => function () {
                    $trucks = $this->truckTypes();
                    $list = implode("\n", array_map(
                        fn (array $t) => "• {$t['name']}: {$t['capacity_label']} — GHS {$t['price_ghs']}",
                        $trucks,
                    ));

                    return "Our available truck sizes:\n{$list}";
                },
                'quick_replies' => [
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                    ['label' => '🏗️ Sand types', 'message' => 'What sand types do you have?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                ],
            ],
            [
                'name' => 'how_to_book',
                'keywords' => ['how to book', 'how to order', 'place an order', 'place order', 'booking', 'make an order'],
                'reply' => fn () => "To place an order:\n1. Select your sand type\n2. Choose a truck size\n3. Enter your delivery address and region\n4. Choose your payment method (MoMo or Cash on Delivery)\n5. Review and confirm your order\n\nYour order will be confirmed immediately and you can track its status in the app.",
                'quick_replies' => [
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                    ['label' => '💳 Payment methods', 'message' => 'What payment methods do you accept?'],
                    ['label' => '📍 Track order', 'message' => 'How do I track my order?'],
                ],
            ],
            [
                'name' => 'payment_methods',
                'keywords' => ['payment method', 'how to pay', 'pay for', 'payment option', 'accept payment'],
                'reply' => fn () => "We accept two payment methods:\n• Mobile Money (MoMo) — MTN, Telecel, or AirtelTigo\n• Cash on Delivery (COD) — pay the driver when your sand arrives\n\nMoMo payments are processed at the time of booking. No PIN is ever stored or transmitted through our app.",
                'quick_replies' => [
                    ['label' => '📱 MoMo help', 'message' => 'How does MoMo payment work?'],
                    ['label' => '💵 Cash on delivery', 'message' => 'How does cash on delivery work?'],
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                ],
            ],
            [
                'name' => 'momo_help',
                'keywords' => ['momo', 'mobile money', 'mtn money', 'telecel cash', 'airteltigo money'],
                'reply' => fn () => "To pay with Mobile Money:\n1. Select MoMo as your payment method during checkout\n2. Enter the name and phone number registered to your MoMo account\n3. Choose your network (MTN, Telecel, or AirtelTigo)\n4. You will receive a prompt on your phone to approve the payment\n\nWe never ask for or store your MoMo PIN.",
                'quick_replies' => [
                    ['label' => '💵 Cash on delivery', 'message' => 'How does cash on delivery work?'],
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                ],
            ],
            [
                'name' => 'cash_on_delivery',
                'keywords' => ['cash on delivery', 'cod', 'pay driver', 'pay on arrival', 'cash payment'],
                'reply' => fn () => "With Cash on Delivery:\n• No upfront payment is required\n• Pay the driver directly when your sand is delivered\n• Have the exact amount ready — the driver may not have change\n• Your order total is confirmed at booking so there are no surprises",
                'quick_replies' => [
                    ['label' => '📱 MoMo help', 'message' => 'How does MoMo payment work?'],
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                ],
            ],
            [
                'name' => 'tracking',
                'keywords' => ['track', 'status', 'where is', 'my order', 'order status', 'delivery status'],
                'reply' => fn () => "Order tracking stages:\n• Confirmed — your order has been received and is being processed\n• On The Way — a truck has been dispatched to your location\n• Delivered — your sand has arrived\n• Cancelled — the order was cancelled\n\nYou can check your order status anytime in the Orders section of the app.",
                'quick_replies' => [
                    ['label' => '⏱️ Delivery time', 'message' => 'How long does delivery take?'],
                    ['label' => '📋 Order history', 'message' => 'Where can I see my past orders?'],
                    ['label' => '⚠️ Report issue', 'message' => 'How do I report a problem?'],
                ],
            ],
            [
                'name' => 'delivery_time',
                'keywords' => ['delivery time', 'how long', 'when will', 'estimated time', 'eta', 'arrive'],
                'reply' => fn () => 'Delivery times depend on your location and truck availability. Most deliveries within Accra are completed within a few hours of confirmation. You will receive status updates as your order progresses through each stage.',
                'quick_replies' => [
                    ['label' => '📍 Track order', 'message' => 'How do I track my order?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                    ['label' => '⚠️ Report issue', 'message' => 'How do I report a problem?'],
                ],
            ],
            [
                'name' => 'order_history',
                'keywords' => ['order history', 'past order', 'previous order', 'my orders', 'old order'],
                'reply' => fn () => 'You can view all your past and current orders in the Orders section of the app. Each order shows the sand type, truck size, delivery details, payment status, and full status history.',
                'quick_replies' => [
                    ['label' => '📍 Track order', 'message' => 'How do I track my order?'],
                    ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                ],
            ],
            [
                'name' => 'report_issue',
                'keywords' => ['report', 'issue', 'problem', 'complaint', 'wrong', 'damaged', 'late'],
                'reply' => fn () => "To report an issue:\n1. Go to the Issues section in the app\n2. Select the type of issue (late delivery, wrong sand type, wrong quantity, damaged goods, payment issue, driver conduct, or other)\n3. Describe the problem in detail\n4. Optionally link the issue to a specific order\n\nOur team will review your report and respond as soon as possible.",
                'quick_replies' => [
                    ['label' => '📍 Track order', 'message' => 'How do I track my order?'],
                    ['label' => '📋 Order history', 'message' => 'Where can I see my past orders?'],
                    ['label' => '💰 Prices', 'message' => 'What are your prices?'],
                ],
            ],
        ];
    }

    private function fallbackRule(): array
    {
        return [
            'name' => 'fallback',
            'reply' => fn () => "I'm not sure I understand. Here are some topics I can help you with:",
            'quick_replies' => $this->defaultQuickReplies(),
        ];
    }

    private function defaultQuickReplies(): array
    {
        return [
            ['label' => '💰 Prices', 'message' => 'What are your prices?'],
            ['label' => '🏗️ Sand types', 'message' => 'What sand types do you have?'],
            ['label' => '🚛 Truck sizes', 'message' => 'What truck sizes are available?'],
            ['label' => '📦 How to book', 'message' => 'How do I place an order?'],
            ['label' => '💳 Payment methods', 'message' => 'What payment methods do you accept?'],
            ['label' => '📍 Track order', 'message' => 'How do I track my order?'],
        ];
    }
}
