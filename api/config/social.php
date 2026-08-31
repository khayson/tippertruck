<?php

declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | Social authentication mode
    |--------------------------------------------------------------------------
    |
    | auto       — use real verification when provider credentials are set,
    |              otherwise fall back to simulated HMAC tokens
    | real       — always require real OAuth token verification
    | simulated  — always accept HMAC demo tokens (local / FYP demos)
    |
    */
    'mode' => env('SOCIAL_AUTH_MODE', 'auto'),

    'demo_secret' => env('SOCIAL_DEMO_SECRET', 'tippertruck-social-demo-secret'),

    'providers' => ['google', 'facebook'],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
    ],

    'facebook' => [
        'app_id' => env('FACEBOOK_APP_ID'),
        'app_secret' => env('FACEBOOK_APP_SECRET'),
    ],
];
