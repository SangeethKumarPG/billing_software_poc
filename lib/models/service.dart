class Service {
  int? id;
  String name;
  String description;
  double price;

  Service({this.id, required this.name, required this.description, required this.price});

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "description": description,
        "price": price,
      };

  factory Service.fromMap(Map<String, dynamic> map) => Service(
        id: map["id"] as int?,
        name: map["name"],
        description: map["description"] ?? "",
        price: (map["price"] as num).toDouble(),
      );
}
