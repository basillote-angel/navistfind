enum ItemType { lost, found }

extension ItemTypeExtension on ItemType {
  static ItemType fromString(String type) {
    switch (type) {
      case 'lost':
        return ItemType.lost;
      case 'found':
        return ItemType.found;
      default:
        throw Exception('Unknown ItemType: $type');
    }
  }
}
