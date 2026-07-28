<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\SandType;
use Illuminate\Database\Seeder;

class SandTypeSeeder extends Seeder
{
    public function run(): void
    {
        $types = [
            ['name' => 'River Sand', 'slug' => 'river-sand', 'description' => 'Natural sand sourced from river beds, ideal for plastering and general construction.', 'icon' => 'wave', 'sort_order' => 1],
            ['name' => 'Quarry Sand', 'slug' => 'quarry-sand', 'description' => 'Crushed stone sand perfect for concrete mixing and structural work.', 'icon' => 'mountain', 'sort_order' => 2],
            ['name' => 'Filling Sand', 'slug' => 'filling-sand', 'description' => 'Coarse sand used for land filling, levelling, and foundation work.', 'icon' => 'layers', 'sort_order' => 3],
        ];

        foreach ($types as $type) {
            SandType::updateOrCreate(['slug' => $type['slug']], $type);
        }
    }
}
