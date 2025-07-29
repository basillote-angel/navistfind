enum NotificationType {
  itemFound,
  itemMatched,
  itemClaimed,
  message,
}

extension NotificationTypeExtension on NotificationType {
  static NotificationType fromString(String type) {
    switch(type) {
      case 'itemFound':
        return NotificationType.itemFound;
      case 'itemMatched':
        return NotificationType.itemMatched;
      case 'itemClaimed':
        return NotificationType.itemClaimed;
      case 'message':
        return NotificationType.message;
      default:
        throw Exception('Unknown NotificationType $type');
    }
  }
}