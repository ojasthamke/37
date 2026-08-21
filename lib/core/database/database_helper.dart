import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = inMemoryDatabasePath;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Use proper app-specific directory on mobile
      final dir = await getApplicationDocumentsDirectory();
      path = p.join(dir.path, 'aplibhaji_admin.db');
    } else {
      // Desktop fallback
      path = 'aplibhaji_shared.db';
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE,
        is_enabled INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT,
        category_id TEXT,
        image_path TEXT,
        description TEXT,
        price REAL,
        unit TEXT,
        is_available INTEGER DEFAULT 1,
        is_enabled INTEGER DEFAULT 1,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT UNIQUE,
        email TEXT,
        address TEXT,
        password TEXT,
        is_logged_in INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_number TEXT UNIQUE,
        customer_id TEXT,
        customer_phone TEXT,
        delivery_address TEXT,
        order_date TEXT,
        status TEXT,
        total_amount REAL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // Order Items Table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        product_id TEXT,
        product_name TEXT,
        price REAL,
        quantity REAL,
        unit TEXT,
        total_price REAL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Seed default settings
    await db.insert('settings', {'key': 'store_name', 'value': 'ApliBhaji Store'});
    await db.insert('settings', {'key': 'store_phone', 'value': '+91 9876543210'});
    await db.insert('settings', {'key': 'store_address', 'value': 'Main Bazar, Pune, Maharashtra'});
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('customers');
    await db.delete('products');
    await db.delete('categories');
  }
}
