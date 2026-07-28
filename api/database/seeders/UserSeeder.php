<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            ['name' => 'Demo Admin', 'email' => 'admin@tippertruck.test', 'phone' => '0200000001', 'role' => UserRole::Admin],
            ['name' => 'Demo Operator', 'email' => 'operator@tippertruck.test', 'phone' => '0200000002', 'role' => UserRole::Operator],
            ['name' => 'Demo Client', 'email' => 'client@tippertruck.test', 'phone' => '0200000003', 'role' => UserRole::Client],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['email' => $user['email']],
                array_merge($user, ['password' => Hash::make('password')]),
            );
        }
    }
}
