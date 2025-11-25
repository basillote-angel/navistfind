enum ItemCategory {
  electronics,
  documents,
  accessories,
  idOrCards,
  clothing,
  bagOrPouches,
  personalItems,
  schoolSupplies,
  others,
}

extension ItemCategoryExtension on ItemCategory {
  static final Map<String, ItemCategory> _normalizedMap = {
    'electronics': ItemCategory.electronics,
    'document': ItemCategory.documents,
    'documents': ItemCategory.documents,
    'accessory': ItemCategory.accessories,
    'accessories': ItemCategory.accessories,
    'idsandcards': ItemCategory.idOrCards,
    'idsndcards': ItemCategory.idOrCards,
    'idcards': ItemCategory.idOrCards,
    'idscards': ItemCategory.idOrCards,
    'idandcards': ItemCategory.idOrCards,
    'idcardsand': ItemCategory.idOrCards,
    'clothing': ItemCategory.clothing,
    'bagpouches': ItemCategory.bagOrPouches,
    'bagandpouches': ItemCategory.bagOrPouches,
    'personalitems': ItemCategory.personalItems,
    'schoolsupplies': ItemCategory.schoolSupplies,
    'other': ItemCategory.others,
    'others': ItemCategory.others,
  };

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static ItemCategory fromString(String category) {
    final normalized = _normalize(category);
    final match = _normalizedMap[normalized];
    if (match != null) return match;
    throw Exception('Unknown ItemCategory: $category');
  }

  static ItemCategory? tryParse(String? category) {
    if (category == null || category.isEmpty) return null;
    final normalized = _normalize(category);
    return _normalizedMap[normalized];
  }

  String get label {
    switch (this) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.documents:
        return 'Documents';
      case ItemCategory.accessories:
        return 'Accessories';
      case ItemCategory.idOrCards:
        return 'IDs & Cards';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.bagOrPouches:
        return 'Bag & Pouches';
      case ItemCategory.personalItems:
        return 'Personal Items';
      case ItemCategory.schoolSupplies:
        return 'School Supplies';
      case ItemCategory.others:
        return 'Others';
    }
  }

  // ✅ Add this:
  String get apiValue => name;
}
