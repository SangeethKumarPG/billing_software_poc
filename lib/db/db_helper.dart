import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/service.dart';
import '../models/bill.dart';
import '../models/staff.dart';

class DBHelper {
  static late Database _db;

  static Future<void> initDb() async {
    String dbPath;

    if (kIsWeb) {
      dbPath = "billing_app.db";
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = join(dir.path, "billing_app.db");
    }

    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2, 
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.execute("DROP TABLE IF EXISTS services");
          await db.execute("DROP TABLE IF EXISTS bills");
          await db.execute("DROP TABLE IF EXISTS bill_items");
          await db.execute("DROP TABLE IF EXISTS staff");
          await _createTables(db);
        },
      ),
    );
  }

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
}
