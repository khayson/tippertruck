<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Enums\IssueStatus;
use App\Enums\IssueType;
use App\Models\Issue;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Issue> */
class IssueFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'order_id' => null,
            'issue_type' => fake()->randomElement(IssueType::cases()),
            'description' => fake()->paragraph(),
            'status' => IssueStatus::Open,
            'admin_response' => null,
            'resolved_at' => null,
        ];
    }
}
