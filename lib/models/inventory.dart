class InventoryItem {
  int? id;
  String name;
  int quantity;
  double price;
  String? category;

  InventoryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.category,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "quantity": quantity,
        "price": price,
        "category": category,
      };

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
        id: map["id"] as int?,
        name: map["name"] as String,
        quantity: map["quantity"] as int,
        price: (map["price"] as num).toDouble(),
        category: map["category"] as String?,
      );
}
