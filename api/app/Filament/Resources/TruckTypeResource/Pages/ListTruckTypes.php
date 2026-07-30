<?php

declare(strict_types=1);

namespace App\Filament\Resources\TruckTypeResource\Pages;

use App\Filament\Resources\TruckTypeResource;
use Filament\Resources\Pages\ListRecords;

class ListTruckTypes extends ListRecords
{
    protected static string $resource = TruckTypeResource::class;
}
