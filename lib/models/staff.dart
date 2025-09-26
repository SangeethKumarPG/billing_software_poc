class Staff {
  int? id;
  String name;
  double salary;
  String gender;

  Staff({this.id, required this.name, required this.salary, required this.gender});

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "salary": salary,
        "gender" : gender
      };

  factory Staff.fromMap(Map<String, dynamic> map) => Staff(
        id: map["id"] as int?,
        name: map["name"],
        salary: (map["salary"] as num).toDouble(),
        gender : map["gender"] ?? "Unspecified"
      );
}
