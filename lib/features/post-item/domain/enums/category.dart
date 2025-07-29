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
  static ItemCategory fromString(String category) {
  switch (category) {
      case 'electronics':
        return ItemCategory.electronics;
      case 'documents':
        return ItemCategory.documents;
      case 'accessories':
        return ItemCategory.accessories;
      case 'idOrCards':
        return ItemCategory.idOrCards;
      case 'clothing':
        return ItemCategory.clothing;
      case 'bagOrPouches':
        return ItemCategory.bagOrPouches;
      case 'personalItems':
        return ItemCategory.personalItems;
      case 'schoolSupplies':
        return ItemCategory.schoolSupplies;
      case 'others':
        return ItemCategory.others;
      default:
        throw Exception('Unknown ItemCategory: $category');
    }
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
