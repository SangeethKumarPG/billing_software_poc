import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/staff.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<Staff> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final data = await DBHelper.getStaff();
    setState(() => _staff = data);
  }

  Future<void> _showDialog([Staff? staff]) async {
    final nameC = TextEditingController(text: staff?.name ?? "");
    final salaryC = TextEditingController(text: staff?.salary.toString() ?? "");
    String selectedGender = staff?.gender ?? "Unspecified";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(staff == null ? "Add Staff" : "Edit Staff"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: salaryC,
                  decoration: const InputDecoration(labelText: "Salary"),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Unspecified", child: Text("Unspecified")),
                ],
                onChanged: (val) => selectedGender = val ?? "Unspecified",
                decoration: const InputDecoration(labelText: "Gender"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                final s = Staff(
                  id: staff?.id,
                  name: nameC.text.trim(),
                  salary: double.tryParse(salaryC.text) ?? 0.0,
                  gender: selectedGender,
                );
                if (staff == null) {
                  await DBHelper.insertStaff(s);
                } else {
                  await DBHelper.updateStaff(s);
                }
                Navigator.pop(context);
                _loadStaff();
              },
              child: const Text("Save"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _staff.isEmpty
          ? const Center(child: Text("No staff added yet"))
          : ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (_, i) {
                final s = _staff[i];
                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.indigo),
                  title: Text(s.name),
                  subtitle: Text(
                      "Salary: ₹${s.salary.toStringAsFixed(2)} • Gender: ${s.gender}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showDialog(s)),
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await DBHelper.deleteStaff(s.id!);
                            _loadStaff();
                          }),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        tooltip: "Add Staff",
        child: const Icon(Icons.add),
      ),
    );
  }
}
