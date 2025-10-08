class Staff {
  int? id;
  String name;
  double salary;
  double overtime;   
  double incentive;  
  String gender;

  Staff({
    this.id,
    required this.name,
    required this.salary,
    this.overtime = 0.0,
    this.incentive = 0.0,
    required this.gender,
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "salary": salary,
        "overtime": overtime,
        "incentive": incentive,
        "gender": gender,
      };

  factory Staff.fromMap(Map<String, dynamic> map) => Staff(
        id: map["id"] as int?,
        name: map["name"],
        salary: (map["salary"] as num).toDouble(),
        overtime: (map["overtime"] ?? 0).toDouble(),
        incentive: (map["incentive"] ?? 0).toDouble(),
        gender: map["gender"] ?? "Unspecified",
      );
}
