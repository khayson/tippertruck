<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sand_truck_prices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sand_type_id')->constrained()->restrictOnDelete();
            $table->foreignId('truck_type_id')->constrained()->restrictOnDelete();
            $table->decimal('price_ghs', 10, 2);
            $table->timestamps();

            $table->unique(['sand_type_id', 'truck_type_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sand_truck_prices');
    }
};
