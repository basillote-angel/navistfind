<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .email-container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #1C2A40;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #1C2A40;
            margin-bottom: 10px;
        }
        .icon {
            font-size: 48px;
            margin-bottom: 15px;
        }
        .title {
            font-size: 22px;
            font-weight: bold;
            color: #1C2A40;
            margin-bottom: 15px;
        }
        .body-content {
            font-size: 16px;
            color: #555;
            line-height: 1.8;
            margin-bottom: 30px;
            white-space: pre-wrap;
        }
        .button {
            display: inline-block;
            padding: 12px 30px;
            background-color: #1C2A40;
            color: #ffffff;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
            margin: 20px 0;
        }
        .button:hover {
            background-color: #2E4A6B;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            text-align: center;
            font-size: 12px;
            color: #999;
        }
        .info-box {
            background-color: #f8f9fa;
            border-left: 4px solid #1C2A40;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .urgent {
            background-color: #fff3cd;
            border-left-color: #ffc107;
        }
        .success {
            background-color: #d4edda;
            border-left-color: #28a745;
        }
        .warning {
            background-color: #fff3cd;
            border-left-color: #ffc107;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <div class="logo">NavistFind</div>
            @if($type === 'claimApproved')
                <div class="icon">🎉</div>
            @elseif($type === 'claimRejected')
                <div class="icon">⚠️</div>
            @elseif($type === 'collectionReminder' || $type === 'collectionOverdue')
                <div class="icon">⏰</div>
            @elseif($type === 'collectionConfirmed')
                <div class="icon">✅</div>
            @elseif($type === 'collectionExpired')
                <div class="icon">⏱️</div>
            @else
                <div class="icon">📬</div>
            @endif
        </div>

        @if($userName)
            <p>Hello {{ $userName }},</p>
        @else
            <p>Hello,</p>
        @endif

        <div class="title">{{ $title }}</div>

        <div class="body-content">{{ $body }}</div>

        @if($type === 'collectionReminder' || $type === 'collectionOverdue')
            <div class="info-box urgent">
                <strong>⏰ Important:</strong> Please collect your item before the deadline. Contact the admin office if you need assistance.
            </div>
        @elseif($type === 'claimApproved')
            <div class="info-box success">
                <strong>✅ Next Steps:</strong> Visit the admin office with a valid ID to collect your item. Bring any supporting evidence.
            </div>
        @elseif($type === 'claimRejected')
            <div class="info-box warning">
                <strong>💡 Tip:</strong> Review the rejection reason and submit a new claim with better evidence if needed.
            </div>
        @elseif($type === 'collectionExpired')
            <div class="info-box warning">
                <strong>ℹ️ Notice:</strong> The collection deadline has passed. The item is now available for other claimants. You can submit a new claim if needed.
            </div>
        @endif

        @if($relatedId)
            <div style="text-align: center;">
                <a href="{{ config('app.url') }}/items/{{ $relatedId }}" class="button">
                    View Details
                </a>
            </div>
        @endif

        <div class="footer">
            <p>This is an automated notification from NavistFind.</p>
            <p>If you have questions, please contact the admin office.</p>
            <p>&copy; {{ date('Y') }} NavistFind. All rights reserved.</p>
        </div>
    </div>
</body>
</html>































