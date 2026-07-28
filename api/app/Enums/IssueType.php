<?php

declare(strict_types=1);

namespace App\Enums;

enum IssueType: string
{
    case LateDelivery = 'late_delivery';
    case WrongSandType = 'wrong_sand_type';
    case WrongQuantity = 'wrong_quantity';
    case DamagedGoods = 'damaged_goods';
    case PaymentIssue = 'payment_issue';
    case DriverConduct = 'driver_conduct';
    case Other = 'other';
}
