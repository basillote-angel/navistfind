<?php

/**
 * COMPLETE INTEGRATION EXAMPLE: ClaimsController with PickupInstructionHelper
 * 
 * This file shows how to integrate PickupInstructionHelper into your existing
 * ClaimsController.php file in your Laravel backend.
 * 
 * File location: C:\CAPSTONE PROJECT\campus-nav\app\Http\Controllers\Admin\ClaimsController.php
 */

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FoundItem;
use App\Models\ClaimedItem;
use App\Jobs\SendNotificationJob;
use App\Helpers\PickupInstructionHelper;  // ADD THIS IMPORT
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ClaimsController extends Controller
{
    /**
     * Approve a claim and send formal pickup instructions
     * 
     * This replaces your existing approve() method
     */
    public function approve(Request $request, $id)
    {
        try {
            // Load item with relationships
            $item = FoundItem::with('claimedBy')->findOrFail($id);
            
            if (!$item->claimedBy) {
                return response()->json([
                    'error' => 'No claimant found for this item'
                ], 400);
            }

            // Update item status
            $item->update([
                'status' => 'CLAIM_APPROVED',
                'collection_deadline' => Carbon::now()->addDays(7), // Default 7 days, adjust as needed
            ]);

            // Update claim status if using ClaimedItem model
            $claim = ClaimedItem::where('found_item_id', $id)
                ->where('status', 'PENDING')
                ->first();
            
            if ($claim) {
                $claim->update(['status' => 'APPROVED']);
            }

            // ============================================
            // GENERATE FORMAL PICKUP INSTRUCTIONS
            // ============================================
            $pickupData = [
                'item_title' => $item->title,
                'collection_location' => $item->collection_location ?? config('app.admin_office_location', 'Administrative Office, Carmen National High School'),
                'collection_deadline' => $item->collection_deadline,
                'collection_instructions' => $item->collection_instructions ?? null,
                'office_hours' => config('app.admin_office_hours', 'Monday-Friday, 8:00 AM - 5:00 PM'),
                'contact_info' => $this->getContactInfo(),
                'claimant_name' => $item->claimedBy->name ?? null,
            ];

            // Generate formal pickup instruction message
            $body = PickupInstructionHelper::generateFormalMessage($pickupData);
            $title = "🎉 Claim Approved: {$item->title}";

            // ============================================
            // SEND NOTIFICATION (Push + Email)
            // ============================================
            SendNotificationJob::dispatch(
                $item->claimedBy->id,
                $title,
                $body,
                'claimApproved',
                $item->id
            );

            Log::info("Claim approved for item {$item->id} by user {$item->claimedBy->id}");

            return response()->json([
                'success' => true,
                'message' => 'Claim approved successfully. User has been notified with pickup instructions.',
                'item' => $item->fresh()
            ]);

        } catch (\Exception $e) {
            Log::error("Error approving claim: " . $e->getMessage());
            Log::error($e->getTraceAsString());
            
            return response()->json([
                'error' => 'Failed to approve claim: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Reject a claim
     */
    public function reject(Request $request, $id)
    {
        try {
            $item = FoundItem::with('claimedBy')->findOrFail($id);
            $rejectionReason = $request->input('rejection_reason', 'No reason provided.');

            // Save claimant ID before clearing
            $claimantId = $item->claimed_by_id;

            // Update item status
            $item->update([
                'status' => 'FOUND_UNCLAIMED',
                'claimed_by_id' => null,
            ]);

            // Update claim status if using ClaimedItem model
            $claim = ClaimedItem::where('found_item_id', $id)
                ->where('status', 'PENDING')
                ->first();
            
            if ($claim) {
                $claim->update([
                    'status' => 'REJECTED',
                    'rejection_reason' => $rejectionReason,
                ]);
            }

            // Send rejection notification
            if ($claimantId) {
                $body = "Your claim for '{$item->title}' was rejected.\n\n";
                $body .= "Reason: {$rejectionReason}\n\n";
                $body .= "You can submit a new claim with additional evidence if needed.";

                SendNotificationJob::dispatch(
                    $claimantId,
                    "⚠️ Claim Rejected: {$item->title}",
                    $body,
                    'claimRejected',
                    $item->id
                );
            }

            return response()->json([
                'success' => true,
                'message' => 'Claim rejected successfully.'
            ]);

        } catch (\Exception $e) {
            Log::error("Error rejecting claim: " . $e->getMessage());
            return response()->json([
                'error' => 'Failed to reject claim: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get contact information from config or defaults
     */
    private function getContactInfo(): string
    {
        $email = config('app.admin_email', 'admin@carmenhighschool.edu.ph');
        $phone = config('app.admin_phone', '(XXX) XXX-XXXX');
        
        return "Email: {$email} | Phone: {$phone}";
    }
}




























