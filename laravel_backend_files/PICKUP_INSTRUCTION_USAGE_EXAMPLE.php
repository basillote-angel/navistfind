<?php

/**
 * EXAMPLE: How to use PickupInstructionHelper in SendNotificationJob
 * 
 * This file shows how to integrate the formal pickup instruction messages
 * into your notification system.
 */

namespace App\Jobs;

use App\Helpers\PickupInstructionHelper;
use App\Models\FoundItem;
use App\Models\ClaimedItem;
use Carbon\Carbon;

class SendNotificationJob
{
    // ... existing code ...

    /**
     * Example: Send claimApproved notification with formal pickup instructions
     */
    public function sendClaimApprovedNotification($userId, $claimId, $foundItemId)
    {
        $claim = ClaimedItem::with('foundItem', 'claimant')->find($claimId);
        $item = FoundItem::find($foundItemId);

        if (!$claim || !$item) {
            return;
        }

        // Prepare data for pickup instruction message
        $pickupData = [
            'item_title' => $item->title,
            'collection_location' => $item->collection_location ?? 'Administrative Office, Carmen National High School',
            'collection_deadline' => $item->collection_deadline,
            'collection_instructions' => $item->collection_instructions,
            'office_hours' => 'Monday-Friday, 8:00 AM - 5:00 PM', // Configure this in your settings
            'contact_info' => 'Email: admin@carmenhighschool.edu.ph | Phone: (XXX) XXX-XXXX', // Configure this
            'claimant_name' => $claim->claimant->name ?? null,
        ];

        // Generate formal pickup instruction message
        $body = PickupInstructionHelper::generateFormalMessage($pickupData);
        $title = "🎉 Claim Approved: {$item->title}";

        // Dispatch notification job
        SendNotificationJob::dispatch(
            $userId,
            $title,
            $body,
            'claimApproved',
            $foundItemId
        );
    }

    /**
     * Example: Send collectionReminder notification
     */
    public function sendCollectionReminder($userId, $foundItemId, $daysRemaining)
    {
        $item = FoundItem::with('claims.claimant')->find($foundItemId);
        $claim = $item->claims()->where('status', 'APPROVED')->first();

        if (!$item || !$claim) {
            return;
        }

        $pickupData = [
            'item_title' => $item->title,
            'collection_location' => $item->collection_location ?? 'Administrative Office, Carmen National High School',
            'collection_deadline' => $item->collection_deadline,
            'collection_instructions' => $item->collection_instructions,
            'office_hours' => 'Monday-Friday, 8:00 AM - 5:00 PM',
            'contact_info' => 'Email: admin@carmenhighschool.edu.ph | Phone: (XXX) XXX-XXXX',
            'claimant_name' => $claim->claimant->name ?? null,
        ];

        $body = PickupInstructionHelper::generateReminderMessage($pickupData, $daysRemaining);
        $title = $daysRemaining <= 1 
            ? "⏰ URGENT: Collection Deadline Tomorrow - {$item->title}"
            : "⏰ Collection Reminder: {$item->title} ({$daysRemaining} days remaining)";

        SendNotificationJob::dispatch(
            $userId,
            $title,
            $body,
            'collectionReminder',
            $foundItemId
        );
    }

    /**
     * Example: Send collectionOverdue notification
     */
    public function sendCollectionOverdue($userId, $foundItemId)
    {
        $item = FoundItem::with('claims.claimant')->find($foundItemId);
        $claim = $item->claims()->where('status', 'APPROVED')->first();

        if (!$item || !$claim) {
            return;
        }

        $pickupData = [
            'item_title' => $item->title,
            'collection_location' => $item->collection_location ?? 'Administrative Office, Carmen National High School',
            'collection_deadline' => $item->collection_deadline,
            'collection_instructions' => $item->collection_instructions,
            'office_hours' => 'Monday-Friday, 8:00 AM - 5:00 PM',
            'contact_info' => 'Email: admin@carmenhighschool.edu.ph | Phone: (XXX) XXX-XXXX',
            'claimant_name' => $claim->claimant->name ?? null,
        ];

        $body = PickupInstructionHelper::generateOverdueMessage($pickupData);
        $title = "🚨 Collection Deadline Passed - {$item->title}";

        SendNotificationJob::dispatch(
            $userId,
            $title,
            $body,
            'collectionOverdue',
            $foundItemId
        );
    }
}

























