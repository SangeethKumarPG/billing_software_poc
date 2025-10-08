class BillItem {
  int? id;
  int serviceId;
  String serviceName;
  double unitPrice;
  int quantity;

  int? staffId;
  String? staffName;

  BillItem({
    this.id,
    required this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    required this.quantity,
    this.staffId,
    this.staffName,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "serviceId": serviceId,
        "serviceName": serviceName,
        "unitPrice": unitPrice,
        "quantity": quantity,
        "staffId": staffId,
        "staffName": staffName,
      };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
        id: map["id"] as int?,
        serviceId: map["serviceId"],
        serviceName: map["serviceName"],
        unitPrice: (map["unitPrice"] as num).toDouble(),
        quantity: map["quantity"],
        staffId: map["staffId"] as int?,
        staffName: map["staffName"] as String?,
      );
}

class Bill {
  int? id;
  String invoiceNo;
  String customerName;
  DateTime date;
  double total;
  List<BillItem> items;

  // ✅ link bill to staff
  int? staffId;
  String? staffName;

  Bill({
    this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.date,
    required this.total,
    required this.items,
    this.staffId,
    this.staffName,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "invoiceNo": invoiceNo,
        "customerName": customerName,
        "date": date.toIso8601String(),
        "total": total,
        "staffId": staffId,
        "staffName": staffName,
      };

  factory Bill.fromMap(Map<String, dynamic> map, List<BillItem> items) => Bill(
        id: map["id"] as int?,
        invoiceNo: map["invoiceNo"],
        customerName: map["customerName"],
        date: DateTime.parse(map["date"]),
        total: (map["total"] as num).toDouble(),
        items: items,
        staffId: map["staffId"] as int?,
        staffName: map["staffName"] as String?,
      );
}
