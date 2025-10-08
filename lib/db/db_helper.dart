import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/service.dart';
import '../models/bill.dart';
import '../models/staff.dart';
import '../models/inventory.dart';

class DBHelper {
  static late Database _db;

  static Future<void> initDb() async {
    String dbPath;

    if (kIsWeb) {
      dbPath = "billing_app.db"; // On web, file path is virtual
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = join(dir.path, "billing_app.db");
    }

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 5, // incremented for new table
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.execute("DROP TABLE IF EXISTS services");
          await db.execute("DROP TABLE IF EXISTS staff");
          await db.execute("DROP TABLE IF EXISTS bills");
          await db.execute("DROP TABLE IF EXISTS bill_items");
          await db.execute("DROP TABLE IF EXISTS inventory");
          await db.execute("DROP TABLE IF EXISTS inventory_history");
          await _createTables(db);
        },
      ),
    );
  }

  // ---------------- CREATE TABLES ----------------
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        gender TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        salary REAL,
        overtime REAL DEFAULT 0,
        incentive REAL DEFAULT 0,
        gender TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNo TEXT NOT NULL,
        customerName TEXT,
        date TEXT,
        total REAL,
        staffId INTEGER,
        staffName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER,
        serviceId INTEGER,
        serviceName TEXT,
        unitPrice REAL,
        quantity INTEGER,
        staffId INTEGER,
        staffName TEXT,
        FOREIGN KEY(billId) REFERENCES bills(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER,
        itemName TEXT,
        action TEXT,
        quantity INTEGER,
        amount REAL,
        date TEXT
      )
    ''');
  }

  // ---------------- SERVICES ----------------
  static Future<int> insertService(Service s) async =>
      await _db.insert("services", s.toMap());

  static Future<List<Service>> getServices() async {
    final rows = await _db.query("services", orderBy: "name");
    return rows.map((r) => Service.fromMap(r)).toList();
  }

  static Future<int> updateService(Service s) async =>
      await _db.update("services", s.toMap(),
          where: "id=?", whereArgs: [s.id]);

  static Future<int> deleteService(int id) async =>
      await _db.delete("services", where: "id=?", whereArgs: [id]);

  // ---------------- STAFF ----------------
  static Future<int> insertStaff(Staff s) async =>
      await _db.insert("staff", s.toMap());

  static Future<List<Staff>> getStaff() async {
    final rows = await _db.query("staff", orderBy: "name");
    return rows.map((r) => Staff.fromMap(r)).toList();
  }

  static Future<int> updateStaff(Staff s) async =>
      await _db.update("staff", s.toMap(),
          where: "id=?", whereArgs: [s.id]);

  static Future<int> deleteStaff(int id) async =>
      await _db.delete("staff", where: "id=?", whereArgs: [id]);

  // ---------------- BILLS ----------------
  static Future<int> insertBill(Bill b) async {
    return await _db.transaction((txn) async {
      final id = await txn.insert("bills", b.toMap());
      for (final item in b.items) {
        final itemMap = item.toMap();
        itemMap["billId"] = id;
        await txn.insert("bill_items", itemMap);
      }
      return id;
    });
  }

  static Future<List<Bill>> getBills() async {
    final rows = await _db.query("bills", orderBy: "date DESC");
    List<Bill> bills = [];
    for (final r in rows) {
      final items = await _db.query("bill_items",
          where: "billId=?", whereArgs: [r["id"]]);
      final billItems = items.map((i) => BillItem.fromMap(i)).toList();
      bills.add(Bill.fromMap(r, billItems));
    }
    return bills;
  }

  // ---------------- INVENTORY ----------------
  static Future<int> insertInventoryItem(InventoryItem item) async {
    final id = await _db.insert("inventory", item.toMap());
    await insertInventoryHistory(
      itemId: id,
      itemName: item.name,
      action: "purchase",
      quantity: item.quantity,
      amount: item.price * item.quantity,
    );
    return id;
  }

  static Future<List<InventoryItem>> getInventory() async {
    final rows = await _db.query("inventory", orderBy: "name");
    return rows.map((r) => InventoryItem.fromMap(r)).toList();
  }

  static Future<int> updateInventoryItem(InventoryItem item) async =>
      await _db.update("inventory", item.toMap(),
          where: "id=?", whereArgs: [item.id]);

  static Future<int> deleteInventoryItem(int id) async =>
      await _db.delete("inventory", where: "id=?", whereArgs: [id]);

  // ---------------- INVENTORY HISTORY ----------------
  static Future<void> insertInventoryHistory({
    required int itemId,
    required String itemName,
    required String action, // 'purchase' or 'usage'
    required int quantity,
    required double amount,
  }) async {
    await _db.insert("inventory_history", {
      "itemId": itemId,
      "itemName": itemName,
      "action": action,
      "quantity": quantity,
      "amount": amount,
      "date": DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getInventoryHistory() async {
    return await _db.query("inventory_history", orderBy: "date DESC");
  }
}
