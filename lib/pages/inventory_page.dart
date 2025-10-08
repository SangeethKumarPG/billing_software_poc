import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/inventory.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<InventoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final data = await DBHelper.getInventory();
    setState(() => _items = data);
  }

  Future<void> _updateQuantity(InventoryItem item, int change) async {
    final updatedQty = (item.quantity + change).clamp(0, double.infinity).toInt();

    // Determine the action type based on change
    String action = change > 0 ? "purchase" : "usage";

    // Calculate the amount for this action
    final quantityChanged = change.abs();
    final amount = item.price * quantityChanged;

    // Create updated item
    final updatedItem = InventoryItem(
      id: item.id,
      name: item.name,
      quantity: updatedQty,
      price: item.price,
      category: item.category,
    );

    // Update quantity in main inventory table
    await DBHelper.updateInventoryItem(updatedItem);

    // Record this change in the inventory history table
    await DBHelper.insertInventoryHistory(
      itemId: item.id!,
      itemName: item.name,
      action: action,
      quantity: quantityChanged,
      amount: amount,
    );

    // Refresh UI
    await _loadInventory();

    // Show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${action == 'purchase' ? 'Added' : 'Used'} $quantityChanged ${item.name}(s) — ₹${amount.toStringAsFixed(2)}",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showDialog([InventoryItem? item]) async {
    final nameC = TextEditingController(text: item?.name ?? "");
    final qtyC = TextEditingController(text: item?.quantity.toString() ?? "");
    final priceC = TextEditingController(text: item?.price.toString() ?? "");
    final catC = TextEditingController(text: item?.category ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? "Add Item" : "Edit Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: qtyC,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: priceC,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: catC,
                  decoration: const InputDecoration(labelText: "Category")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newItem = InventoryItem(
                id: item?.id,
                name: nameC.text.trim(),
                quantity: int.tryParse(qtyC.text) ?? 0,
                price: double.tryParse(priceC.text) ?? 0.0,
                category: catC.text.trim(),
              );
              if (item == null) {
                await DBHelper.insertInventoryItem(newItem);
              } else {
                await DBHelper.updateInventoryItem(newItem);
              }
              Navigator.pop(context);
              _loadInventory();
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
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Quantity")),
            DataColumn(label: Text("Price")),
            DataColumn(label: Text("Category")),
            DataColumn(label: Text("Actions")),
          ],
          rows: _items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.name)),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: item.quantity > 0
                        ? () => _updateQuantity(item, -1)
                        : null,
                  ),
                  Text(item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _updateQuantity(item, 1),
                  ),
                ],
              )),
              DataCell(Text("₹${item.price.toStringAsFixed(2)}")),
              DataCell(Text(item.category ?? "")),
              DataCell(Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showDialog(item)),
                  IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await DBHelper.deleteInventoryItem(item.id!);
                        _loadInventory();
                      }),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
