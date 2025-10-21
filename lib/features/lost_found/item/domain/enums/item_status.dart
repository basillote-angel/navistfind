enum ItemStatus { claimed, unclaimed }

extension ItemStatusExtension on ItemStatus {
  static ItemStatus fromString(String status) {
    switch (status) {
      case 'claimed':
        return ItemStatus.claimed;
      case 'unclaimed':
        return ItemStatus.unclaimed;
      default:
        throw Exception('Unknown ItemStatus: $status');
    }
  }
}
