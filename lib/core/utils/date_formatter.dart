/// Centralized date formatting utilities
/// Replaces duplicate date formatting functions across the codebase
class DateFormatter {
  /// Formats a date string to relative time (e.g., "2 days ago", "Yesterday")
  /// Used in: item_card, posted_item_card, profile_screen, recommendations_screen
  static String formatRelativeDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.isNegative) return 'Just now';
      if (diff.inDays > 7) return '${date.month}/${date.day}/${date.year}';
      if (diff.inDays >= 2) return '${diff.inDays} days ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inHours >= 1) {
        return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
      }
      if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
      return 'Just now';
    } catch (_) {
      return 'Unknown date';
    }
  }

  /// Formats a DateTime to full date string (e.g., "Monday, January 15, 2024")
  /// Used in: home_page
  static String formatFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats date string for API requests (YYYY-MM-DD)
  /// Used in: post_item_service
  static String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

