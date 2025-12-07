<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ClaimNotificationEmail extends Mailable
{
    use Queueable, SerializesModels;

    public $title;
    public $body;
    public $type;
    public $relatedId;
    public $userName;

    /**
     * Create a new message instance.
     */
    public function __construct($title, $body, $type, $relatedId, $userName = null)
    {
        $this->title = $title;
        $this->body = $body;
        $this->type = $type;
        $this->relatedId = $relatedId;
        $this->userName = $userName;
    }

    /**
     * Build the message.
     */
    public function build()
    {
        $subject = $this->title;
        
        // Customize subject based on notification type
        switch ($this->type) {
            case 'claimSubmitted':
                $subject = '✅ Claim Submitted - NavistFind';
                break;
            case 'claimApproved':
                $subject = '🎉 Claim Approved - NavistFind';
                break;
            case 'claimRejected':
                $subject = '⚠️ Claim Update - NavistFind';
                break;
            case 'collectionReminder':
                $subject = '⏰ Collection Reminder - NavistFind';
                break;
            case 'collectionOverdue':
                $subject = '🚨 Collection Overdue - NavistFind';
                break;
            case 'collectionExpired':
                $subject = '⏱️ Collection Expired - NavistFind';
                break;
            case 'collectionConfirmed':
                $subject = '✅ Item Collected - NavistFind';
                break;
            default:
                $subject = $this->title;
        }

        return $this->subject($subject)
                    ->view('emails.claim-notification')
                    ->with([
                        'title' => $this->title,
                        'body' => $this->body,
                        'type' => $this->type,
                        'relatedId' => $this->relatedId,
                        'userName' => $this->userName,
                    ]);
    }
}


































