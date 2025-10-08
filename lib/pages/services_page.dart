import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Service> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final data = await DBHelper.getServices();
    setState(() => _services = data);
  }

  Future<void> _showServiceDialog([Service? service]) async {
    final nameC = TextEditingController(text: service?.name ?? "");
    final descC = TextEditingController(text: service?.description ?? "");
    final priceC = TextEditingController(text: service?.price?.toString() ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(service == null ? "Add Service" : "Edit Service"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: "Description")),
              TextField(
                  controller: priceC,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newService = Service(
                id: service?.id,
                name: nameC.text.trim(),
                description: descC.text.trim(),
                price: double.tryParse(priceC.text) ?? 0.0,
              );
              if (service == null) {
                await DBHelper.insertService(newService);
              } else {
                await DBHelper.updateService(newService);
              }
              Navigator.pop(context);
              _loadServices();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _services.isEmpty
          ? const Center(child: Text("No services available"))
          : ListView.builder(
              itemCount: _services.length,
              itemBuilder: (_, i) {
                final s = _services[i];
                return ListTile(
                  title: Text(s.name),
                  subtitle: Text(
                      "₹${s.price.toStringAsFixed(2)} • ${s.description}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showServiceDialog(s)),
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await DBHelper.deleteService(s.id!);
                            _loadServices();
                          }),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(),
        tooltip: "Add Service",
        child: const Icon(Icons.add),
      ),
    );
  }
}
