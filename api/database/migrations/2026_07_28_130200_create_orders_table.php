<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_ref')->unique();

            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('sand_type_id')->constrained()->restrictOnDelete();
            $table->foreignId('truck_type_id')->constrained()->restrictOnDelete();

            $table->decimal('price_ghs', 10, 2);
            $table->decimal('delivery_fee_ghs', 10, 2)->default(0);
            $table->decimal('total_ghs', 10, 2);

            $table->string('recipient_name');
            $table->string('recipient_phone');
            $table->string('street_address');
            $table->string('region');
            $table->string('city');
            $table->string('landmark')->nullable();
            $table->text('delivery_note')->nullable();

            $table->string('payment_method');
            $table->string('payment_status')->default('pending');
            $table->string('momo_name')->nullable();
            $table->string('momo_phone')->nullable();
            $table->string('momo_network')->nullable();

            $table->string('status')->default('confirmed');
            $table->foreignId('assigned_operator_id')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('dispatched_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
