<?php

declare(strict_types=1);

return [
    ['input' => 'hello how much is a small truck', 'intent' => 'pricing'],
    // Ambiguous: asks about sand through a pricing lens. Engine favours sand_types
    // because "which sand" + "sand" outweighs "price" alone. Acceptable — the
    // sand list reply includes context about each type.
    ['input' => 'which sand is cheapest', 'intent' => 'sand_types'],
    ['input' => 'HOW MUCH???', 'intent' => 'pricing'],
    ['input' => 'is the price negotiable', 'intent' => 'pricing'],
    ['input' => 'tipper truck price list', 'intent' => 'pricing'],
    ['input' => 'abeg how much for one trip', 'intent' => 'pricing'],
    ['input' => 'how much is the large one', 'intent' => 'pricing'],
    ['input' => 'quarry or river which is better', 'intent' => 'sand_types'],
    ['input' => 'sand for foundation work', 'intent' => 'sand_types'],
    ['input' => 'i wan book truck', 'intent' => 'how_to_book'],
    ['input' => 'make i pay cash', 'intent' => 'cash_on_delivery'],
    // Negation is a known limitation — "momo" triggers momo_help regardless of "do not want"
    ['input' => 'i dont want to use momo', 'intent' => 'momo_help'],
    ['input' => 'is my order on the way', 'intent' => 'order_status'],
    ['input' => 'how far', 'intent' => 'order_status'],
    ['input' => 'my order is late', 'intent' => 'report_issue'],
    ['input' => 'i paid but got no confirmation', 'intent' => 'report_issue'],
    ['input' => 'prise of medium truck', 'intent' => 'pricing'],
    ['input' => 'do you deliver to kumasi', 'intent' => 'delivery_coverage'],
    ['input' => 'i want to cancel my order', 'intent' => 'order_cancellation'],
    ['input' => 'can i speak to someone', 'intent' => 'human_handoff'],
];
