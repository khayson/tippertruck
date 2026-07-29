<?php

declare(strict_types=1);

/**
 * Chatbot test corpus: real-world utterances mapped to expected intents.
 * Written as a Ghanaian customer would type — lowercase, abbreviated,
 * with typos and surrounding words. DO NOT copy keywords from the rules.
 */
return [
    // --- greeting (5) ---
    ['input' => 'hello there', 'intent' => 'greeting'],
    ['input' => 'hi good morning', 'intent' => 'greeting'],
    ['input' => 'hey', 'intent' => 'greeting'],
    ['input' => 'Good Evening please', 'intent' => 'greeting'],
    ['input' => 'good afternoon o', 'intent' => 'greeting'],

    // --- pricing (6) ---
    ['input' => 'hw much for sand delivery', 'intent' => 'pricing'],
    ['input' => 'whats the cost of medium lorry', 'intent' => 'pricing'],
    ['input' => 'i want to know the charges', 'intent' => 'pricing'],
    ['input' => 'pls how much be the rate for tipper', 'intent' => 'pricing'],
    ['input' => 'show me prices for trucks', 'intent' => 'pricing'],
    ['input' => 'what is the fee for large truck', 'intent' => 'pricing'],

    // --- sand_types (5) ---
    ['input' => 'what kind of sand do u sell', 'intent' => 'sand_types'],
    ['input' => 'which sand types are available', 'intent' => 'sand_types'],
    ['input' => 'do u have quarry sand', 'intent' => 'sand_types'],
    ['input' => 'tell me about your sand options', 'intent' => 'sand_types'],
    ['input' => 'i need river sand information', 'intent' => 'sand_types'],

    // --- truck_sizes (5) ---
    ['input' => 'what sizes of lorry do u have', 'intent' => 'truck_sizes'],
    ['input' => 'how big is the medium tipper', 'intent' => 'truck_sizes'],
    ['input' => 'tell me the tonnage of your trucks', 'intent' => 'truck_sizes'],
    ['input' => 'do u have small lorry for 2 tonnes', 'intent' => 'truck_sizes'],
    ['input' => 'i want to know about truck capacity pls', 'intent' => 'truck_sizes'],

    // --- how_to_book (5) ---
    ['input' => 'how do i place an order for sand', 'intent' => 'how_to_book'],
    ['input' => 'hw can i book a delivery', 'intent' => 'how_to_book'],
    ['input' => 'i want to make an order', 'intent' => 'how_to_book'],
    ['input' => 'pls how do i order sand', 'intent' => 'how_to_book'],
    ['input' => 'steps to book a tipper', 'intent' => 'how_to_book'],

    // --- payment_methods (4) ---
    ['input' => 'what payment options do you accept', 'intent' => 'payment_methods'],
    ['input' => 'how can i pay for my order', 'intent' => 'payment_methods'],
    ['input' => 'what methods of payment do u offer', 'intent' => 'payment_methods'],
    ['input' => 'which payment do u take', 'intent' => 'payment_methods'],

    // --- momo_help (4) ---
    ['input' => 'how does mtn momo payment work', 'intent' => 'momo_help'],
    ['input' => 'i want to pay with mobile money', 'intent' => 'momo_help'],
    ['input' => 'telecel cash how does it work', 'intent' => 'momo_help'],
    ['input' => 'can i use airteltigo money to pay', 'intent' => 'momo_help'],

    // --- cash_on_delivery (4) ---
    ['input' => 'can i pay cash on delivery', 'intent' => 'cash_on_delivery'],
    ['input' => 'i want to pay the driver when he arrives', 'intent' => 'cash_on_delivery'],
    ['input' => 'do u accept cod', 'intent' => 'cash_on_delivery'],
    ['input' => 'i prefer to pay on delivery please', 'intent' => 'cash_on_delivery'],

    // --- report_issue (4 general + 8 complaint-routed) ---
    ['input' => 'i want to report a problem with my delivery', 'intent' => 'report_issue'],
    ['input' => 'the sand i received was not enough how do i complain', 'intent' => 'report_issue', 'suggested_issue_type' => 'wrong_quantity'],
    ['input' => 'hw do i report an issue', 'intent' => 'report_issue'],
    ['input' => 'i have a complaint about the driver', 'intent' => 'report_issue'],

    // complaint vocabulary — late_delivery
    ['input' => 'my delivery is late where is the truck', 'intent' => 'report_issue', 'suggested_issue_type' => 'late_delivery'],
    ['input' => 'my sand has not come and i am still waiting', 'intent' => 'report_issue', 'suggested_issue_type' => 'late_delivery'],

    // complaint vocabulary — payment_issue
    ['input' => 'i paid but i have not received any confirmation', 'intent' => 'report_issue', 'suggested_issue_type' => 'payment_issue'],
    ['input' => 'my money was deducted but the order shows unpaid', 'intent' => 'report_issue', 'suggested_issue_type' => 'payment_issue'],

    // complaint vocabulary — wrong_sand_type
    ['input' => 'you gave me the wrong sand type', 'intent' => 'report_issue', 'suggested_issue_type' => 'wrong_sand_type'],

    // complaint vocabulary — damaged_goods
    ['input' => 'the sand was contaminated with rubbish', 'intent' => 'report_issue', 'suggested_issue_type' => 'damaged_goods'],

    // complaint vocabulary — driver_conduct
    ['input' => 'the driver was very rude to me at the site', 'intent' => 'report_issue', 'suggested_issue_type' => 'driver_conduct'],

    // complaint vocabulary — wrong_quantity
    ['input' => 'the sand was not enough less than what i ordered', 'intent' => 'report_issue', 'suggested_issue_type' => 'wrong_quantity'],

    // --- order_status (5) ---
    ['input' => 'where is my order', 'intent' => 'order_status'],
    ['input' => 'check my delivery status', 'intent' => 'order_status'],
    ['input' => 'how far is my sand', 'intent' => 'order_status'],
    ['input' => 'what is the status of my order pls', 'intent' => 'order_status'],
    ['input' => 'has my order been dispatched', 'intent' => 'order_status'],

    // --- order_cancellation (3) ---
    ['input' => 'i want to cancel my order', 'intent' => 'order_cancellation'],
    ['input' => 'how do i cancel an order', 'intent' => 'order_cancellation'],
    ['input' => 'cancel this order for me pls', 'intent' => 'order_cancellation'],

    // --- tracking (3) ---
    ['input' => 'what are the tracking stages', 'intent' => 'tracking'],
    ['input' => 'explain the order stages to me', 'intent' => 'tracking'],
    ['input' => 'what does confirmed and on the way mean', 'intent' => 'tracking'],

    // --- delivery_time (4) ---
    ['input' => 'how long will my delivery take', 'intent' => 'delivery_time'],
    ['input' => 'when will the sand arrive', 'intent' => 'delivery_time'],
    ['input' => 'what is the estimated delivery time', 'intent' => 'delivery_time'],
    ['input' => 'how many hours for delivery in accra', 'intent' => 'delivery_time'],

    // --- delivery_coverage (3) ---
    ['input' => 'do you deliver to tamale', 'intent' => 'delivery_coverage'],
    ['input' => 'which regions do you cover', 'intent' => 'delivery_coverage'],
    ['input' => 'can i get delivery to cape coast', 'intent' => 'delivery_coverage'],

    // --- order_history (3) ---
    ['input' => 'where can i see my old orders', 'intent' => 'order_history'],
    ['input' => 'show me my previous orders pls', 'intent' => 'order_history'],
    ['input' => 'i want to view my order history', 'intent' => 'order_history'],

    // --- human_handoff (3) ---
    ['input' => 'can i speak to a real person', 'intent' => 'human_handoff'],
    ['input' => 'i want to talk to someone please', 'intent' => 'human_handoff'],
    ['input' => 'is there a customer service number', 'intent' => 'human_handoff'],

    // --- known limitation: negation not handled ---
    // "momo" triggers momo_help regardless of "do not want" context
    ['input' => 'i dont want to use momo', 'intent' => 'momo_help'],

    // --- fallback: gibberish, off-topic, ambiguous (12) ---
    ['input' => 'asdfghjkl', 'intent' => 'fallback'],
    ['input' => 'what is the weather today', 'intent' => 'fallback'],
    ['input' => 'can you help me with my homework', 'intent' => 'fallback'],
    ['input' => 'who is the president of ghana', 'intent' => 'fallback'],
    ['input' => 'lol ok thanks bye', 'intent' => 'fallback'],
    ['input' => 'hmm', 'intent' => 'fallback'],
    ['input' => 'eiiii charley', 'intent' => 'fallback'],
    ['input' => 'play music for me', 'intent' => 'fallback'],
    ['input' => 'what time is it now', 'intent' => 'fallback'],
    ['input' => 'tell me a joke', 'intent' => 'fallback'],
    ['input' => 'where is your office located', 'intent' => 'fallback'],
    ['input' => '12345', 'intent' => 'fallback'],

    // --- typo tolerance (5) ---
    ['input' => 'what are your pricee', 'intent' => 'pricing'],
    ['input' => 'i need delivry information', 'intent' => 'delivery_time'],
    ['input' => 'bookng a truck', 'intent' => 'how_to_book'],
    ['input' => 'paymentt methods available', 'intent' => 'payment_methods'],
    ['input' => 'trackng my order', 'intent' => 'order_status'],
];
