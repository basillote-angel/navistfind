# Prompt for Cursor AI - Verify Enhanced Notification Messages

Copy and paste this prompt into Cursor AI in the Flutter project:

---

## Task: Verify Enhanced Notification Messages Display

I need you to verify that the Flutter mobile app is correctly displaying the enhanced formal notification messages from the backend.

### Background
The Laravel backend has been updated to send enhanced, formal notification messages via `NotificationMessageService`. These messages include:
- Formal greetings ("Dear [Name],")
- Structured sections with separators (━━━)
- Professional formatting
- Clear next steps and contact information

### What to Check

1. **Verify Notification Display**
   - Check if `notification_modals.dart` correctly displays the full notification body from the backend
   - Verify that `_MessageSection` widget properly parses and formats:
     - Greetings ("Dear [Name],")
     - Section headers (e.g., "NEXT STEPS", "REASON FOR DECISION")
     - Separator lines (━━━)
     - Bullet points (•)
     - Emoji-prefixed lines (📍, 🕐, ⏰, etc.)
     - Closing lines ("Best regards", "Thank you")

2. **Check API Integration**
   - Verify that `NotificationResource` from the API returns `title` and `body` fields
   - Confirm that the Flutter app uses these fields directly (not hardcoded messages)
   - Check that notification body is displayed as-is from the backend

3. **Verify Message Parsing**
   - Check if `_MessageSection` in `notification_modals.dart` correctly handles:
     - Multi-line formatted messages
     - Section headers and separators
     - Proper text formatting and styling
   - Ensure no hardcoded messages override the backend messages

4. **Test Cases to Verify**
   - **Claim Submitted**: Should show "Claim Submission Confirmed" with formal message starting with "Dear [Name],"
   - **Claim Rejected**: Should show "Claim Status Update - Not Approved" with full formal rejection message
   - **Claim Approved**: Should show "Claim Approved - Collection Instructions" with pickup details
   - All messages should display the full formatted body from the backend

### Files to Check

1. `lib/features/notifications/presentation/notification_modals.dart`
   - `_MessageSection` widget
   - Modal display components
   - Message formatting logic

2. `lib/features/notifications/data/notifications_service.dart`
   - API response parsing
   - Notification model mapping

3. `lib/features/notifications/domain/models/notification_item.dart`
   - Notification data structure

4. `lib/core/notifications/push_notification_listener.dart`
   - Push notification handling
   - Message display from FCM

### Expected Behavior

When a user receives a notification:
1. The notification body should be the full formal message from the backend
2. The message should be properly formatted with:
   - Greeting at the top
   - Structured sections
   - Clear formatting
   - Professional closing
3. No hardcoded messages should override the backend messages
4. The Flutter app should display exactly what the backend sends

### What to Report

Please check and report:
1. ✅ Are notification bodies displayed directly from the backend API?
2. ✅ Does `_MessageSection` correctly parse and format the enhanced messages?
3. ✅ Are there any hardcoded messages that override backend messages?
4. ✅ Do all notification types (claimSubmitted, claimRejected, claimApproved) display enhanced messages?
5. ✅ Is the message formatting (sections, separators, bullets) displayed correctly?

### Example Enhanced Message Format

The backend sends messages like this:
```
Dear BASILLOTE ANGEL ROSE,

We have successfully received your claim request for "Oppo A5s Red phone".

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Your claim is now under review by our administration team
2. You will receive a notification once a decision has been made
...

Best regards,
NavistFind Administration
Carmen National High School
```

The Flutter app should display this exactly as formatted, with proper styling for sections, bullets, and formatting.

---

**Please verify all of the above and report any issues or confirmations.**




