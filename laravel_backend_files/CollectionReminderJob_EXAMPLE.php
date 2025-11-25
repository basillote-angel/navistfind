<?php

/**
 * EXAMPLE: Scheduled Job for Collection Reminders
 * 
 * This job should run daily to check for items approaching collection deadline
 * and send reminder notifications.
 * 
 * File location: C:\CAPSTONE PROJECT\campus-nav\app\Jobs\CollectionReminderJob.php
 * 
 * Schedule in: app/Console/Kernel.php
 * $schedule->job(new CollectionReminderJob)->daily();
 */

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Models\FoundItem;
use App\Models\ClaimedItem;
use App\Jobs\SendNotificationJob;
use App\Helpers\PickupInstructionHelper;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class CollectionReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Execute the job.
     */
    public function handle()
    {
        try {
            // Find items with approved claims that have collection deadlines
            $items = FoundItem::where('status', 'CLAIM_APPROVED')
                ->whereNotNull('collection_deadline')
                ->with('claimedBy')
                ->get();

            foreach ($items as $item) {
                if (!$item->claimedBy || !$item->collection_deadline) {
                    continue;
                }

                $deadline = Carbon::parse($item->collection_deadline);
                $now = Carbon::now();
                $daysRemaining = $now->diffInDays($deadline, false);

                // Send reminder 3 days before deadline
                if ($daysRemaining === 3) {
                    $this->sendReminder($item, $daysRemaining);
                }
                // Send urgent reminder 1 day before deadline
                elseif ($daysRemaining === 1) {
                    $this->sendReminder($item, $daysRemaining);
                }
                // Send overdue notification if deadline passed but within grace period
                elseif ($daysRemaining < 0 && $daysRemaining >= -3) {
                    $this->sendOverdue($item);
                }
            }

            Log::info("Collection reminder job completed. Checked " . $items->count() . " items.");

        } catch (\Exception $e) {
            Log::error("CollectionReminderJob failed: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Send collection reminder notification
     */
    private function sendReminder(FoundItem $item, int $daysRemaining)
    {
        $pickupData = [
            'item_title' => $item->title,
            'collection_location' => $item->collection_location ?? config('app.admin_office_location', 'Administrative Office'),
            'collection_deadline' => $item->collection_deadline,
            'collection_instructions' => $item->collection_instructions,
            'office_hours' => config('app.admin_office_hours', 'Monday-Friday, 8:00 AM - 5:00 PM'),
            'contact_info' => $this->getContactInfo(),
            'claimant_name' => $item->claimedBy->name ?? null,
        ];

        $body = PickupInstructionHelper::generateReminderMessage($pickupData, $daysRemaining);
        $title = $daysRemaining <= 1 
            ? "⏰ URGENT: Collection Deadline Tomorrow - {$item->title}"
            : "⏰ Collection Reminder: {$item->title} ({$daysRemaining} days remaining)";

        SendNotificationJob::dispatch(
            $item->claimedBy->id,
            $title,
            $body,
            'collectionReminder',
            $item->id
        );

        Log::info("Collection reminder sent to user {$item->claimedBy->id} for item {$item->id} ({$daysRemaining} days remaining)");
    }

    /**
     * Send overdue notification
     */
    private function sendOverdue(FoundItem $item)
    {
        $pickupData = [
            'item_title' => $item->title,
            'collection_location' => $item->collection_location ?? config('app.admin_office_location', 'Administrative Office'),
            'collection_deadline' => $item->collection_deadline,
            'collection_instructions' => $item->collection_instructions,
            'office_hours' => config('app.admin_office_hours', 'Monday-Friday, 8:00 AM - 5:00 PM'),
            'contact_info' => $this->getContactInfo(),
            'claimant_name' => $item->claimedBy->name ?? null,
        ];

        $body = PickupInstructionHelper::generateOverdueMessage($pickupData);
        $title = "🚨 Collection Deadline Passed - {$item->title}";

        SendNotificationJob::dispatch(
            $item->claimedBy->id,
            $title,
            $body,
            'collectionOverdue',
            $item->id
        );

        Log::info("Overdue notification sent to user {$item->claimedBy->id} for item {$item->id}");
    }

    /**
     * Get contact information
     */
    private function getContactInfo(): string
    {
        $email = config('app.admin_email', 'admin@carmenhighschool.edu.ph');
        $phone = config('app.admin_phone', '(XXX) XXX-XXXX');
        
        return "Email: {$email} | Phone: {$phone}";
    }
}

























