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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        try { await db.execute("ALTER TABLE products ADD COLUMN order_now_stock REAL DEFAULT 0.0"); } catch (_) {}
        try { await db.execute("ALTER TABLE products ADD COLUMN order_now_price REAL DEFAULT 0.0"); } catch (_) {}
        try { await db.execute("ALTER TABLE products ADD COLUMN order_now_mrp REAL DEFAULT 0.0"); } catch (_) {}
        try { await db.execute("ALTER TABLE products ADD COLUMN order_now_cost_price REAL DEFAULT 0.0"); } catch (_) {}
        try { await db.execute("ALTER TABLE products ADD COLUMN order_now_is_available INTEGER DEFAULT 1"); } catch (_) {}
      },
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
        area_id TEXT,
        road_id TEXT,
        sub_road_id TEXT,
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
        delivery_date TEXT,
        area_id TEXT,
        area_name TEXT,
        road_id TEXT,
        road_name TEXT,
        sub_road_id TEXT,
        sub_road_name TEXT,
        customer_name TEXT,
        offline_order_no TEXT,
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
    await db.insert('settings', {'key': 'delivery_charge', 'value': '30'});
    await db.insert('settings', {'key': 'free_delivery_threshold', 'value': '300'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new route fields to customers
      try { await db.execute("ALTER TABLE customers ADD COLUMN area_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE customers ADD COLUMN road_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE customers ADD COLUMN sub_road_id TEXT"); } catch (_) {}

      // Add new route and snapshot fields to orders
      try { await db.execute("ALTER TABLE orders ADD COLUMN delivery_date TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN area_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN area_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN road_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN road_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN sub_road_id TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN sub_road_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN customer_name TEXT"); } catch (_) {}
      try { await db.execute("ALTER TABLE orders ADD COLUMN offline_order_no TEXT"); } catch (_) {}
    }
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
