<?php

declare(strict_types=1);

namespace App\Services;

use App\Enums\OrderStatus;
use App\Models\ChatbotUnmatchedLog;
use App\Models\Order;
use App\Models\SandType;
use App\Models\TruckType;
use App\Models\User;

class ChatbotService
{
    private const float CONFIDENCE_THRESHOLD = 0.20;

    private const float MAX_CONFIDENCE_SCORE = 10.0;

    private const array CONTRACTIONS = [
        "what's" => 'what is',
        'whats' => 'what is',
        "how's" => 'how is',
        'hows' => 'how is',
        "where's" => 'where is',
        'wheres' => 'where is',
        "it's" => 'it is',
        "i'm" => 'i am',
        'im' => 'i am',
        "don't" => 'do not',
        'dont' => 'do not',
        "can't" => 'can not',
        'cant' => 'can not',
        "won't" => 'will not',
        'wont' => 'will not',
        "didn't" => 'did not',
        'didnt' => 'did not',
        "isn't" => 'is not',
        'isnt' => 'is not',
        "i'll" => 'i will',
        "you're" => 'you are',
        'youre' => 'you are',
        "they're" => 'they are',
        'theyre' => 'they are',
        "we're" => 'we are',
        "i've" => 'i have',
        'ive' => 'i have',
        "there's" => 'there is',
        'theres' => 'there is',
        'hw' => 'how',
        'u' => 'you',
        'pls' => 'please',
        'plz' => 'please',
        'abt' => 'about',
        'yr' => 'your',
        'ur' => 'your',
        'dat' => 'that',
        'dis' => 'this',
        'dey' => 'they',
        'dem' => 'them',
        'wen' => 'when',
        'whr' => 'where',
        'shd' => 'should',
        'wld' => 'would',
        'cld' => 'could',
        'bk' => 'book',
        'thx' => 'thanks',
        'tnx' => 'thanks',
        'thnks' => 'thanks',
        'nid' => 'need',
        'nd' => 'and',
        'wan' => 'want',
        'giv' => 'give',
        'b4' => 'before',
    ];

    private const array MULTI_WORD_SYNONYMS = [
        'mobile money' => 'momo',
        'mtn momo' => 'momo',
        'mtn money' => 'momo',
        'telecel cash' => 'momo',
        'airteltigo money' => 'momo',
        'cash on delivery' => 'cod',
        'pay on delivery' => 'cod',
        'pay on arrival' => 'cod',
    ];

    private const array SINGLE_WORD_SYNONYMS = [
        'lorry' => 'truck',
        'tipper' => 'truck',
        'cost' => 'price',
        'charge' => 'price',
        'rate' => 'price',
        'fee' => 'price',
        'pricing' => 'price',
        'charges' => 'price',
        'rates' => 'price',
        'fees' => 'price',
        'aggregate' => 'sand',
        'mtn' => 'momo',
        'telecel' => 'momo',
        'airteltigo' => 'momo',
    ];

    public function respond(string $message, ?User $user = null, int $unmatchedCount = 0): array
    {
        $normalised = $this->normalise($message);
        $tokens = $this->tokenise($normalised);
        $entities = $this->extractEntities($tokens);
        $scores = $this->scoreAllRules($tokens, $entities, $user);

        usort($scores, function (array $a, array $b) {
            if ($b['score'] !== $a['score']) {
                return $b['score'] <=> $a['score'];
            }

            return $a['priority'] <=> $b['priority'];
        });

        $best = $scores[0] ?? null;
        $confidence = $best ? round(min(1.0, $best['score'] / self::MAX_CONFIDENCE_SCORE), 2) : 0.0;

        if ($best === null || $best['score'] <= 0 || $confidence < self::CONFIDENCE_THRESHOLD) {
            return $this->buildUncertainResponse($message, $scores, $confidence, $user, $unmatchedCount, $entities);
        }

        $rule = $best['rule'];
        $reply = ($rule['reply'])($entities, $user);

        return [
            'reply' => $reply,
            'matched_rule' => $rule['name'],
            'confidence' => $confidence,
            'entities' => $this->formatEntities($entities),
            'quick_replies' => $rule['quick_replies'],
            'unmatched_count' => $unmatchedCount,
        ];
    }

    public function normalise(string $message): string
    {
        $text = mb_strtolower(trim($message));

        $text = (string) preg_replace('/[^\w\s]/u', ' ', $text);

        foreach (self::CONTRACTIONS as $contraction => $expansion) {
            $text = (string) preg_replace('/\b'.preg_quote($contraction, '/').'\b/u', $expansion, $text);
        }

        $sorted = self::MULTI_WORD_SYNONYMS;
        uksort($sorted, fn (string $a, string $b) => mb_strlen($b) <=> mb_strlen($a));
        foreach ($sorted as $phrase => $canonical) {
            $text = str_replace($phrase, $canonical, $text);
        }

        $text = (string) preg_replace('/\s+/', ' ', trim($text));

        return $text;
    }

    /**
     * @return string[]
     */
    public function tokenise(string $normalised): array
    {
        $tokens = preg_split('/\s+/', $normalised, -1, PREG_SPLIT_NO_EMPTY);

        if ($tokens === false) {
            return [];
        }

        return array_map(function (string $token): string {
            return self::SINGLE_WORD_SYNONYMS[$token] ?? $token;
        }, $tokens);
    }

    /**
     * @param  string[]  $tokens
     * @return array{truck_type: ?array, sand_type: ?array}
     */
    public function extractEntities(array $tokens): array
    {
        $result = ['truck_type' => null, 'sand_type' => null];
        $inputText = implode(' ', $tokens);

        $truckTypes = TruckType::where('is_active', true)->get(['id', 'name', 'slug', 'capacity_label', 'price_ghs']);
        foreach ($truckTypes as $truck) {
            $nameLower = mb_strtolower($truck->name);
            $slugLower = mb_strtolower($truck->slug);

            if (str_contains($inputText, $nameLower)) {
                $result['truck_type'] = $truck->toArray();
                break;
            }

            if ($this->wordBoundaryMatch($inputText, $slugLower) || $this->fuzzyMatchInTokens($slugLower, $tokens)) {
                $result['truck_type'] = $truck->toArray();
                break;
            }
        }

        $sandTypes = SandType::where('is_active', true)->get(['id', 'name', 'slug', 'description']);
        foreach ($sandTypes as $sand) {
            $nameLower = mb_strtolower($sand->name);
            $slugLower = str_replace('-', ' ', mb_strtolower($sand->slug));

            if (str_contains($inputText, $nameLower)) {
                $result['sand_type'] = $sand->toArray();
                break;
            }

            $slugParts = explode(' ', $slugLower);
            foreach ($slugParts as $part) {
                if ($part === 'sand' || mb_strlen($part) < 4) {
                    continue;
                }
                if ($this->fuzzyMatchInTokens($part, $tokens)) {
                    $result['sand_type'] = $sand->toArray();
                    break 2;
                }
            }
        }

        return $result;
    }

    private function wordBoundaryMatch(string $haystack, string $needle): bool
    {
        return (bool) preg_match('/\b'.preg_quote($needle, '/').'\b/', $haystack);
    }

    /**
     * @param  string[]  $tokens
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     * @return array<int, array{rule: array, score: float, priority: int}>
     */
    private function scoreAllRules(array $tokens, array $entities, ?User $user): array
    {
        $rules = $this->rules($user);
        $results = [];

        foreach ($rules as $rule) {
            $score = 0.0;

            foreach ($rule['patterns'] as $pattern) {
                $patternTokens = explode(' ', $pattern['phrase']);
                $weight = (float) $pattern['weight'];

                if ($this->matchesPhrase($tokens, $patternTokens)) {
                    $score += $weight;
                }
            }

            if ($entities['truck_type'] !== null || $entities['sand_type'] !== null) {
                $entityBonus = $rule['entity_bonus'] ?? 0.0;
                if ($entityBonus > 0) {
                    $score += $entityBonus;
                }
            }

            $results[] = [
                'rule' => $rule,
                'score' => $score,
                'priority' => $rule['priority'],
            ];
        }

        return $results;
    }

    /**
     * @param  string[]  $inputTokens
     * @param  string[]  $phraseTokens
     */
    private function matchesPhrase(array $inputTokens, array $phraseTokens): bool
    {
        if (count($phraseTokens) === 1) {
            return $this->matchesToken($phraseTokens[0], $inputTokens);
        }

        $len = count($inputTokens);
        $phraseLen = count($phraseTokens);

        for ($i = 0; $i <= $len - $phraseLen; $i++) {
            $match = true;
            for ($j = 0; $j < $phraseLen; $j++) {
                if (! $this->tokensMatch($inputTokens[$i + $j], $phraseTokens[$j])) {
                    $match = false;
                    break;
                }
            }
            if ($match) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  string[]  $inputTokens
     */
    private function matchesToken(string $keyword, array $inputTokens): bool
    {
        foreach ($inputTokens as $token) {
            if ($this->tokensMatch($token, $keyword)) {
                return true;
            }
        }

        return false;
    }

    private function tokensMatch(string $input, string $keyword): bool
    {
        if ($input === $keyword) {
            return true;
        }

        $keyLen = mb_strlen($keyword);

        if ($keyLen < 5) {
            return false;
        }

        $inputLen = mb_strlen($input);
        if ($inputLen < 3) {
            return false;
        }

        $maxDistance = $keyLen >= 8 ? 2 : 1;

        return levenshtein($input, $keyword) <= $maxDistance;
    }

    /**
     * @param  string[]  $tokens
     */
    private function fuzzyMatchInTokens(string $word, array $tokens): bool
    {
        foreach ($tokens as $token) {
            if ($this->tokensMatch($token, $word)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     */
    private function formatEntities(array $entities): object|array
    {
        $result = [];

        if ($entities['truck_type'] !== null) {
            $result['truck_type'] = [
                'id' => $entities['truck_type']['id'],
                'name' => $entities['truck_type']['name'],
            ];
        }

        if ($entities['sand_type'] !== null) {
            $result['sand_type'] = [
                'id' => $entities['sand_type']['id'],
                'name' => $entities['sand_type']['name'],
            ];
        }

        return empty($result) ? (object) [] : $result;
    }

    /**
     * @param  array<int, array{rule: array, score: float, priority: int}>  $scores
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     */
    private function buildUncertainResponse(
        string $rawMessage,
        array $scores,
        float $confidence,
        ?User $user,
        int $unmatchedCount,
        array $entities,
    ): array {
        $topScoring = array_filter($scores, fn (array $s) => $s['score'] > 0);
        usort($topScoring, fn (array $a, array $b) => $b['score'] <=> $a['score']);
        $topIntents = array_slice($topScoring, 0, 3);

        $topIntentName = $topIntents[0]['rule']['name'] ?? null;

        ChatbotUnmatchedLog::create([
            'user_id' => $user?->id,
            'message' => $rawMessage,
            'top_intent' => $topIntentName,
            'confidence' => $confidence,
        ]);

        $newUnmatchedCount = $unmatchedCount + 1;

        $quickReplies = [];
        foreach ($topIntents as $intent) {
            $label = $intent['rule']['suggestion_label'] ?? ucfirst(str_replace('_', ' ', $intent['rule']['name']));
            $msg = $intent['rule']['suggestion_message'] ?? ucfirst(str_replace('_', ' ', $intent['rule']['name']));
            $quickReplies[] = ['label' => $label, 'message' => $msg];
        }

        if (empty($quickReplies)) {
            $quickReplies = $this->defaultQuickReplies();
        }

        if ($newUnmatchedCount >= 2) {
            $quickReplies[] = ['label' => 'Report an issue', 'message' => 'I want to report an issue'];
        }

        $reply = 'I am not sure I understand your question. Here are some topics I can help you with:';

        return [
            'reply' => $reply,
            'matched_rule' => 'fallback',
            'confidence' => $confidence,
            'entities' => $this->formatEntities($entities),
            'quick_replies' => $quickReplies,
            'unmatched_count' => $newUnmatchedCount,
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
            fn (array $t) => "- {$t['name']}: GHS {$t['price_ghs']} ({$t['capacity_label']})",
            $trucks,
        ));
    }

    /**
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     */
    private function buildPricingReply(array $entities): string
    {
        if ($entities['truck_type'] !== null) {
            $t = $entities['truck_type'];

            return "{$t['name']} costs GHS {$t['price_ghs']} and carries {$t['capacity_label']}.";
        }

        return "Here are our current prices:\n".$this->formatPriceList();
    }

    /**
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     */
    private function buildSandTypesReply(array $entities): string
    {
        if ($entities['sand_type'] !== null) {
            $s = $entities['sand_type'];

            return "{$s['name']}: {$s['description']}";
        }

        $types = $this->sandTypes();
        $list = implode("\n", array_map(
            fn (array $t) => "- {$t['name']}: {$t['description']}",
            $types,
        ));

        return "We offer the following sand types:\n{$list}";
    }

    /**
     * @param  array{truck_type: ?array, sand_type: ?array}  $entities
     */
    private function buildTruckSizesReply(array $entities): string
    {
        if ($entities['truck_type'] !== null) {
            $t = $entities['truck_type'];

            return "{$t['name']} carries {$t['capacity_label']} and costs GHS {$t['price_ghs']}.";
        }

        $trucks = $this->truckTypes();
        $list = implode("\n", array_map(
            fn (array $t) => "- {$t['name']}: {$t['capacity_label']} at GHS {$t['price_ghs']}",
            $trucks,
        ));

        return "Our available truck sizes:\n{$list}";
    }

    private function buildOrderStatusReply(?User $user): string
    {
        if ($user === null) {
            return 'Please log in to check your order status. You can view all your orders in the Orders section of the app.';
        }

        $terminalStatuses = [OrderStatus::Delivered->value, OrderStatus::Cancelled->value];

        $activeOrders = Order::where('user_id', $user->id)
            ->whereNotIn('status', $terminalStatuses)
            ->orderByDesc('created_at')
            ->get(['id', 'order_ref', 'status']);

        if ($activeOrders->isEmpty()) {
            return 'You have no active orders at the moment. Would you like to place a new order?';
        }

        $latest = $activeOrders->first();
        $status = OrderStatus::from($latest->status->value);
        $progress = $status->progressPercent();

        if ($activeOrders->count() === 1) {
            return "Your order {$latest->order_ref} is currently {$status->label()} ({$progress}% complete).";
        }

        $otherCount = $activeOrders->count() - 1;

        return "Your most recent order {$latest->order_ref} is currently {$status->label()} ({$progress}% complete). You have {$otherCount} other active ".($otherCount === 1 ? 'order' : 'orders').'.';
    }

    /**
     * @return array<int, array>
     */
    private function rules(?User $user): array
    {
        return [
            [
                'name' => 'greeting',
                'priority' => 1,
                'patterns' => [
                    ['phrase' => 'hello', 'weight' => 3],
                    ['phrase' => 'hi', 'weight' => 3],
                    ['phrase' => 'hey', 'weight' => 3],
                    ['phrase' => 'good morning', 'weight' => 5],
                    ['phrase' => 'good afternoon', 'weight' => 5],
                    ['phrase' => 'good evening', 'weight' => 5],
                    ['phrase' => 'welcome', 'weight' => 3],
                ],
                'reply' => fn () => 'Hello! Welcome to Tipper Truck. I can help you with pricing, sand types, truck sizes, booking, payments, and more. What would you like to know?',
                'quick_replies' => $this->defaultQuickReplies(),
                'suggestion_label' => 'Say hello',
                'suggestion_message' => 'Hello',
            ],
            [
                'name' => 'pricing',
                'priority' => 2,
                'entity_bonus' => 2.0,
                'patterns' => [
                    ['phrase' => 'price', 'weight' => 3],
                    ['phrase' => 'how much', 'weight' => 4],
                ],
                'reply' => fn (array $entities) => $this->buildPricingReply($entities),
                'quick_replies' => [
                    ['label' => 'Sand types', 'message' => 'What sand types do you have?'],
                    ['label' => 'Truck sizes', 'message' => 'What truck sizes are available?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                ],
                'suggestion_label' => 'View prices',
                'suggestion_message' => 'What are your prices?',
            ],
            [
                'name' => 'sand_types',
                'priority' => 3,
                'entity_bonus' => 2.0,
                'patterns' => [
                    ['phrase' => 'sand type', 'weight' => 5],
                    ['phrase' => 'type of sand', 'weight' => 5],
                    ['phrase' => 'kind of sand', 'weight' => 5],
                    ['phrase' => 'types of sand', 'weight' => 5],
                    ['phrase' => 'which sand', 'weight' => 4],
                    ['phrase' => 'what sand', 'weight' => 4],
                    ['phrase' => 'sand options', 'weight' => 4],
                    ['phrase' => 'sand', 'weight' => 2],
                ],
                'reply' => fn (array $entities) => $this->buildSandTypesReply($entities),
                'quick_replies' => [
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                    ['label' => 'Truck sizes', 'message' => 'What truck sizes are available?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                ],
                'suggestion_label' => 'Sand types',
                'suggestion_message' => 'What sand types do you have?',
            ],
            [
                'name' => 'truck_sizes',
                'priority' => 4,
                'entity_bonus' => 2.0,
                'patterns' => [
                    ['phrase' => 'truck size', 'weight' => 5],
                    ['phrase' => 'truck capacity', 'weight' => 5],
                    ['phrase' => 'size of truck', 'weight' => 5],
                    ['phrase' => 'how big', 'weight' => 4],
                    ['phrase' => 'tonnage', 'weight' => 3],
                    ['phrase' => 'tonnes', 'weight' => 3],
                    ['phrase' => 'tons', 'weight' => 3],
                    ['phrase' => 'truck', 'weight' => 2],
                ],
                'reply' => fn (array $entities) => $this->buildTruckSizesReply($entities),
                'quick_replies' => [
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                    ['label' => 'Sand types', 'message' => 'What sand types do you have?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                ],
                'suggestion_label' => 'Truck sizes',
                'suggestion_message' => 'What truck sizes are available?',
            ],
            [
                'name' => 'how_to_book',
                'priority' => 5,
                'patterns' => [
                    ['phrase' => 'place order', 'weight' => 5],
                    ['phrase' => 'place an order', 'weight' => 5],
                    ['phrase' => 'how to book', 'weight' => 5],
                    ['phrase' => 'how to order', 'weight' => 5],
                    ['phrase' => 'how do i order', 'weight' => 5],
                    ['phrase' => 'make an order', 'weight' => 5],
                    ['phrase' => 'make order', 'weight' => 5],
                    ['phrase' => 'order sand', 'weight' => 5],
                    ['phrase' => 'booking', 'weight' => 3],
                    ['phrase' => 'book', 'weight' => 3],
                ],
                'reply' => fn () => "To place an order:\n1. Select your sand type\n2. Choose a truck size\n3. Enter your delivery address and region\n4. Choose your payment method (MoMo or Cash on Delivery)\n5. Review and confirm your order\n\nYour order will be confirmed immediately and you can track its status in the app.",
                'quick_replies' => [
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                    ['label' => 'Payment methods', 'message' => 'What payment methods do you accept?'],
                    ['label' => 'Track order', 'message' => 'How do I track my order?'],
                ],
                'suggestion_label' => 'How to book',
                'suggestion_message' => 'How do I place an order?',
            ],
            [
                'name' => 'payment_methods',
                'priority' => 6,
                'patterns' => [
                    ['phrase' => 'payment method', 'weight' => 5],
                    ['phrase' => 'payment option', 'weight' => 5],
                    ['phrase' => 'payment methods', 'weight' => 5],
                    ['phrase' => 'how can i pay', 'weight' => 5],
                    ['phrase' => 'how to pay', 'weight' => 5],
                    ['phrase' => 'methods of payment', 'weight' => 5],
                    ['phrase' => 'accept payment', 'weight' => 4],
                    ['phrase' => 'payment', 'weight' => 3],
                ],
                'reply' => fn () => "We accept two payment methods:\n- Mobile Money (MoMo) via MTN, Telecel, or AirtelTigo\n- Cash on Delivery (COD), where you pay the driver when your sand arrives\n\nMoMo payments are processed at the time of booking. No PIN is ever stored or transmitted through our app.",
                'quick_replies' => [
                    ['label' => 'MoMo help', 'message' => 'How does MoMo payment work?'],
                    ['label' => 'Cash on delivery', 'message' => 'How does cash on delivery work?'],
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                ],
                'suggestion_label' => 'Payment methods',
                'suggestion_message' => 'What payment methods do you accept?',
            ],
            [
                'name' => 'momo_help',
                'priority' => 7,
                'patterns' => [
                    ['phrase' => 'momo', 'weight' => 4],
                ],
                'reply' => fn () => "To pay with Mobile Money:\n1. Select MoMo as your payment method during checkout\n2. Enter the name and phone number registered to your MoMo account\n3. Choose your network (MTN, Telecel, or AirtelTigo)\n4. You will receive a prompt on your phone to approve the payment\n\nWe never ask for or store your MoMo PIN.",
                'quick_replies' => [
                    ['label' => 'Cash on delivery', 'message' => 'How does cash on delivery work?'],
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                ],
                'suggestion_label' => 'MoMo help',
                'suggestion_message' => 'How does MoMo payment work?',
            ],
            [
                'name' => 'cash_on_delivery',
                'priority' => 8,
                'patterns' => [
                    ['phrase' => 'cod', 'weight' => 4],
                    ['phrase' => 'pay the driver', 'weight' => 5],
                    ['phrase' => 'pay driver', 'weight' => 5],
                    ['phrase' => 'cash', 'weight' => 2],
                ],
                'reply' => fn () => "With Cash on Delivery:\n- No upfront payment is required\n- Pay the driver directly when your sand is delivered\n- Have the exact amount ready, as the driver may not have change\n- Your order total is confirmed at booking so there are no surprises",
                'quick_replies' => [
                    ['label' => 'MoMo help', 'message' => 'How does MoMo payment work?'],
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                ],
                'suggestion_label' => 'Cash on delivery',
                'suggestion_message' => 'How does cash on delivery work?',
            ],
            [
                'name' => 'order_status',
                'priority' => 9,
                'patterns' => [
                    ['phrase' => 'where is my', 'weight' => 5],
                    ['phrase' => 'my order', 'weight' => 4],
                    ['phrase' => 'order status', 'weight' => 5],
                    ['phrase' => 'delivery status', 'weight' => 5],
                    ['phrase' => 'how far is', 'weight' => 5],
                    ['phrase' => 'how far', 'weight' => 4],
                    ['phrase' => 'been dispatched', 'weight' => 4],
                    ['phrase' => 'status of my', 'weight' => 5],
                ],
                'reply' => fn (array $entities, ?User $u) => $this->buildOrderStatusReply($u),
                'quick_replies' => [
                    ['label' => 'Delivery time', 'message' => 'How long does delivery take?'],
                    ['label' => 'Order history', 'message' => 'Where can I see my past orders?'],
                    ['label' => 'Report issue', 'message' => 'I want to report a problem'],
                ],
                'suggestion_label' => 'Order status',
                'suggestion_message' => 'Where is my order?',
            ],
            [
                'name' => 'tracking',
                'priority' => 10,
                'patterns' => [
                    ['phrase' => 'tracking stage', 'weight' => 5],
                    ['phrase' => 'tracking stages', 'weight' => 5],
                    ['phrase' => 'order stages', 'weight' => 5],
                    ['phrase' => 'stages', 'weight' => 3],
                    ['phrase' => 'confirmed', 'weight' => 2],
                    ['phrase' => 'on the way', 'weight' => 3],
                    ['phrase' => 'tracking', 'weight' => 3],
                ],
                'reply' => fn () => "Order tracking stages:\n- Confirmed: your order has been received and is being processed\n- On The Way: a truck has been dispatched to your location\n- Delivered: your sand has arrived\n- Cancelled: the order was cancelled\n\nYou can check your order status anytime in the Orders section of the app.",
                'quick_replies' => [
                    ['label' => 'Delivery time', 'message' => 'How long does delivery take?'],
                    ['label' => 'Order history', 'message' => 'Where can I see my past orders?'],
                    ['label' => 'Report issue', 'message' => 'I want to report a problem'],
                ],
                'suggestion_label' => 'Tracking stages',
                'suggestion_message' => 'What are the tracking stages?',
            ],
            [
                'name' => 'delivery_time',
                'priority' => 11,
                'patterns' => [
                    ['phrase' => 'delivery time', 'weight' => 5],
                    ['phrase' => 'how long', 'weight' => 4],
                    ['phrase' => 'when will', 'weight' => 4],
                    ['phrase' => 'estimated time', 'weight' => 4],
                    ['phrase' => 'how many hours', 'weight' => 4],
                    ['phrase' => 'eta', 'weight' => 3],
                    ['phrase' => 'arrive', 'weight' => 3],
                    ['phrase' => 'delivery take', 'weight' => 5],
                    ['phrase' => 'delivery', 'weight' => 2],
                ],
                'reply' => fn () => 'Delivery times depend on your location and truck availability. Most deliveries within Accra are completed within a few hours of confirmation. You will receive status updates as your order progresses through each stage.',
                'quick_replies' => [
                    ['label' => 'Track order', 'message' => 'How do I track my order?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                    ['label' => 'Report issue', 'message' => 'I want to report a problem'],
                ],
                'suggestion_label' => 'Delivery time',
                'suggestion_message' => 'How long does delivery take?',
            ],
            [
                'name' => 'order_history',
                'priority' => 12,
                'patterns' => [
                    ['phrase' => 'order history', 'weight' => 5],
                    ['phrase' => 'past orders', 'weight' => 5],
                    ['phrase' => 'past order', 'weight' => 5],
                    ['phrase' => 'previous orders', 'weight' => 5],
                    ['phrase' => 'previous order', 'weight' => 5],
                    ['phrase' => 'old orders', 'weight' => 5],
                    ['phrase' => 'old order', 'weight' => 5],
                    ['phrase' => 'my orders', 'weight' => 3],
                    ['phrase' => 'history', 'weight' => 3],
                ],
                'reply' => fn () => 'You can view all your past and current orders in the Orders section of the app. Each order shows the sand type, truck size, delivery details, payment status, and full status history.',
                'quick_replies' => [
                    ['label' => 'Track order', 'message' => 'How do I track my order?'],
                    ['label' => 'How to book', 'message' => 'How do I place an order?'],
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                ],
                'suggestion_label' => 'Order history',
                'suggestion_message' => 'Where can I see my past orders?',
            ],
            [
                'name' => 'report_issue',
                'priority' => 13,
                'patterns' => [
                    ['phrase' => 'report', 'weight' => 3],
                    ['phrase' => 'issue', 'weight' => 3],
                    ['phrase' => 'problem', 'weight' => 3],
                    ['phrase' => 'complaint', 'weight' => 3],
                    ['phrase' => 'complain', 'weight' => 3],
                ],
                'reply' => fn () => "To report an issue:\n1. Go to the Issues section in the app\n2. Select the type of issue (late delivery, wrong sand type, wrong quantity, damaged goods, payment issue, driver conduct, or other)\n3. Describe the problem in detail\n4. Optionally link the issue to a specific order\n\nOur team will review your report and respond as soon as possible.",
                'quick_replies' => [
                    ['label' => 'Track order', 'message' => 'How do I track my order?'],
                    ['label' => 'Order history', 'message' => 'Where can I see my past orders?'],
                    ['label' => 'Prices', 'message' => 'What are your prices?'],
                ],
                'suggestion_label' => 'Report issue',
                'suggestion_message' => 'I want to report a problem',
            ],
        ];
    }

    private function defaultQuickReplies(): array
    {
        return [
            ['label' => 'Prices', 'message' => 'What are your prices?'],
            ['label' => 'Sand types', 'message' => 'What sand types do you have?'],
            ['label' => 'Truck sizes', 'message' => 'What truck sizes are available?'],
            ['label' => 'How to book', 'message' => 'How do I place an order?'],
            ['label' => 'Payment methods', 'message' => 'What payment methods do you accept?'],
            ['label' => 'Track order', 'message' => 'How do I track my order?'],
        ];
    }
}
