class ShoppingListModel {
  final int id;
  final String name;
  final bool isArchived;
  final int itemCount;
  final int checkedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingListModel({
    required this.id,
    required this.name,
    this.isArchived = false,
    this.itemCount = 0,
    this.checkedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => itemCount > 0 ? checkedCount / itemCount : 0;

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as int,
      name: json['name'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
      itemCount: json['itemCount'] as int? ?? 0,
      checkedCount: json['checkedCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ShoppingListItemModel {
  final int id;
  final int? productId;
  final String? productName;
  final String? productImageUrl;
  final String name;
  final int quantity;
  final bool isChecked;

  ShoppingListItemModel({
    required this.id,
    this.productId,
    this.productName,
    this.productImageUrl,
    required this.name,
    this.quantity = 1,
    this.isChecked = false,
  });

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemModel(
      id: json['id'] as int,
      productId: json['productId'] as int?,
      productName: json['productName'] as String?,
      productImageUrl: json['productImageUrl'] as String?,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }
}

class ShoppingListDetail {
  final int id;
  final String name;
  final bool isArchived;
  final List<ShoppingListItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingListDetail({
    required this.id,
    required this.name,
    this.isArchived = false,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingListDetail.fromJson(Map<String, dynamic> json) {
    return ShoppingListDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      isArchived: json['isArchived'] as bool? ?? false,
      items: (json['items'] as List?)
              ?.map((e) => ShoppingListItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
