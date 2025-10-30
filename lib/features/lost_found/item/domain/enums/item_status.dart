enum ItemStatus { open, matched, closed, unclaimed, returned }

extension ItemStatusExtension on ItemStatus {
  static ItemStatus fromString(String status) {
    switch (status) {
      case 'open':
        return ItemStatus.open;
      case 'matched':
        return ItemStatus.matched;
      case 'closed':
        return ItemStatus.closed;
      case 'unclaimed':
        return ItemStatus.unclaimed;
      case 'returned':
        return ItemStatus.returned;
      case 'claimed': // legacy mapping
        return ItemStatus.returned;
      default:
        throw Exception('Unknown ItemStatus: $status');
    }
  }
}
