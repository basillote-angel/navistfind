<?php

/**
 * EXAMPLE: How to update your existing SendNotificationJob.php
 * 
 * Add this code to your existing SendNotificationJob handle() method
 * File location: app/Jobs/SendNotificationJob.php
 */

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use App\Models\User;
use App\Models\AppNotification;
use App\Mail\ClaimNotificationEmail;  // ADD THIS IMPORT
use Illuminate\Support\Facades\Mail;  // ADD THIS IMPORT

class SendNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $userId;
    public $title;
    public $body;
    public $type;
    public $relatedId;

    public function __construct($userId, $title, $body, $type, $relatedId = null)
    {
        $this->userId = $userId;
        $this->title = $title;
        $this->body = $body;
        $this->type = $type;
        $this->relatedId = $relatedId;
    }

    /**
     * Execute the job.
     * ADD EMAIL SENDING CODE HERE (after your existing push notification code)
     */
    public function handle()
    {
        try {
            $user = User::find($this->userId);
            if (!$user) {
                Log::warning("User not found for notification: {$this->userId}");
                return;
            }

            // 1. Create database notification record (YOUR EXISTING CODE)
            $notification = AppNotification::create([
                'user_id' => $this->userId,
                'type' => $this->type,
                'title' => $this->title,
                'body' => $this->body,
                'related_id' => $this->relatedId,
                'read_at' => null,
            ]);

            // 2. Send push notification via FCM (YOUR EXISTING CODE)
            // ... your existing FCM push notification code ...

            // ============================================
            // 3. ADD THIS: Send email notification (NEW)
            // ============================================
            if ($user->email) {
                try {
                    Mail::to($user->email)->send(
                        new ClaimNotificationEmail(
                            $this->title,
                            $this->body,
                            $this->type,
                            $this->relatedId,
                            $user->name ?? null
                        )
                    );
                    Log::info("Email notification sent to {$user->email} for type: {$this->type}");
                } catch (\Exception $e) {
                    Log::error("Failed to send email notification: " . $e->getMessage());
                    // Don't fail the entire job if email fails
                }
            } else {
                Log::warning("User {$this->userId} has no email address");
            }
            // ============================================

        } catch (\Exception $e) {
            Log::error("SendNotificationJob failed: " . $e->getMessage());
            throw $e;
        }
    }
}









