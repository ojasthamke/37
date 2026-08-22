import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import 'database_seeder.dart';

// ==========================================
// ABSTRACT REPOSITORY INTERFACES
// ==========================================

abstract class CategoryRepository {
  Future<List<Map<String, dynamic>>> getCategories();
  Future<void> addCategory(String name, bool isEnabled);
  Future<void> updateCategory(String id, String name, bool isEnabled);
  Future<void> deleteCategory(String id);
  Future<void> toggleCategory(String id, bool isEnabled);
}

abstract class ProductRepository {
  Future<List<Map<String, dynamic>>> getProducts({String? search, String? categoryId});
  Future<void> addProduct({
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  });
  Future<void> updateProduct({
    required String id,
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  });
  Future<void> deleteProduct(String id);
  Future<void> toggleProduct(String id, bool isEnabled);
  Future<void> toggleAvailability(String id, bool isAvailable);
}

abstract class CustomerRepository {
  Future<List<Map<String, dynamic>>> getCustomers({String? search});
  Future<Map<String, dynamic>?> getCustomerById(String id);
  Future<List<Map<String, dynamic>>> getCustomerOrderHistory(String customerId);
  Future<void> updateCustomer(String id, String name, String phone, String address);
  Future<void> deleteCustomer(String id);
}

abstract class OrderRepository {
  Future<List<Map<String, dynamic>>> getOrders({String? status, String? search});
  Future<Map<String, dynamic>?> getOrderById(String id);
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> deleteOrder(String id);
}

abstract class SettingsRepository {
  Future<Map<String, String>> getSettings();
  Future<void> updateSetting(String key, String value);
  Future<void> resetDatabase();
  Future<void> seedDatabase();
}

// ==========================================
// SQLITE IMPLEMENTATIONS (OFFLINE FALLBACK)
// ==========================================

class SQLiteCategoryRepository implements CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await _dbHelper.database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  @override
  Future<void> addCategory(String name, bool isEnabled) async {
    final db = await _dbHelper.database;
    await db.insert('categories', {
      'id': _uuid.v4(),
      'name': name,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateCategory(String id, String name, bool isEnabled) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {
        'name': name,
        'is_enabled': isEnabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> toggleCategory(String id, bool isEnabled) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class SQLiteProductRepository implements ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Map<String, dynamic>>> getProducts({String? search, String? categoryId}) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereClause += '(products.name LIKE ? OR products.description LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'products.category_id = ?';
      whereArgs.add(categoryId);
    }

    final query = '''
      SELECT products.*, categories.name as category_name 
      FROM products 
      LEFT JOIN categories ON products.category_id = categories.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY products.name ASC
    ''';

    return await db.rawQuery(query, whereArgs);
  }

  @override
  Future<void> addProduct({
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('products', {
      'id': _uuid.v4(),
      'name': name,
      'category_id': categoryId,
      'image_path': '',
      'description': description,
      'price': price,
      'unit': unit,
      'is_available': isAvailable ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateProduct({
    required String id,
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
        'unit': unit,
        'is_available': isAvailable ? 1 : 0,
        'is_enabled': isEnabled ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> toggleProduct(String id, bool isEnabled) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'is_available': isAvailable ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class SQLiteCustomerRepository implements CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Map<String, dynamic>>> getCustomers({String? search}) async {
    final db = await _dbHelper.database;
    if (search != null && search.isNotEmpty) {
      return await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ? OR address LIKE ?',
        whereArgs: ['%$search%', '%$search%', '%$search%'],
        orderBy: 'name ASC',
      );
    }
    return await db.query('customers', orderBy: 'name ASC');
  }

  @override
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final res = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerOrderHistory(String customerId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'order_date DESC',
    );
  }

  @override
  Future<void> updateCustomer(String id, String name, String phone, String address) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      {
        'name': name,
        'phone': phone,
        'address': address,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.rawDelete('''
      DELETE FROM order_items 
      WHERE order_id IN (SELECT id FROM orders WHERE customer_id = ?)
    ''', [id]);
    await db.delete('orders', where: 'customer_id = ?', whereArgs: [id]);
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

class SQLiteOrderRepository implements OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Map<String, dynamic>>> getOrders({String? status, String? search}) async {
    final db = await _dbHelper.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null && status != 'All') {
      whereClause += 'orders.status = ?';
      whereArgs.add(status);
    }

    if (search != null && search.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(orders.order_number LIKE ? OR customers.name LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    final query = '''
      SELECT orders.*, customers.name as customer_name, customers.phone as customer_phone
      FROM orders
      LEFT JOIN customers ON orders.customer_id = customers.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY orders.order_date DESC
    ''';

    return await db.rawQuery(query, whereArgs);
  }

  @override
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    final db = await _dbHelper.database;
    const query = '''
      SELECT orders.*, customers.name as customer_name, customers.phone as customer_phone
      FROM orders
      LEFT JOIN customers ON orders.customer_id = customers.id
      WHERE orders.id = ?
    ''';
    final res = await db.rawQuery(query, [id]);
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await _dbHelper.database;
    return await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  @override
  Future<void> deleteOrder(String id) async {
    final db = await _dbHelper.database;
    await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }
}

class SQLiteSettingsRepository implements SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<Map<String, String>> getSettings() async {
    final db = await _dbHelper.database;
    final res = await db.query('settings');
    return Map.fromEntries(res.map((r) => MapEntry(r['key'] as String, r['value'] as String)));
  }

  @override
  Future<void> updateSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> resetDatabase() async {
    await _dbHelper.clearDatabase();
  }

  @override
  Future<void> seedDatabase() async {
    await DatabaseSeeder.seedAll();
  }
}

// ==========================================
// SUPABASE IMPLEMENTATIONS (REMOTE BACKEND)
// ==========================================

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final List<dynamic> res = await _client.from('categories').select().order('name', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> addCategory(String name, bool isEnabled) async {
    await _client.from('categories').insert({
      'name': name,
      'is_enabled': isEnabled,
    });
  }

  @override
  Future<void> updateCategory(String id, String name, bool isEnabled) async {
    await _client.from('categories').update({
      'name': name,
      'is_enabled': isEnabled,
    }).eq('id', id);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  @override
  Future<void> toggleCategory(String id, bool isEnabled) async {
    await _client.from('categories').update({
      'is_enabled': isEnabled,
    }).eq('id', id);
  }
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getProducts({String? search, String? categoryId}) async {
    var query = _client.from('products').select('*, categories(name)');
    
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,description.ilike.%$search%');
    }
    
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    
    final List<dynamic> res = await query.order('name', ascending: true);
    return res.map((p) {
      final Map<String, dynamic> mapped = Map.from(p);
      final cat = p['categories'] as Map<String, dynamic>?;
      mapped['category_name'] = cat != null ? cat['name'] : 'N/A';
      return mapped;
    }).toList();
  }

  @override
  Future<void> addProduct({
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'category_id': categoryId,
      'image_path': '',
      'description': description,
      'price': price,
      'unit': unit,
      'is_available': isAvailable,
      'is_enabled': isEnabled,
    });
  }

  @override
  Future<void> updateProduct({
    required String id,
    required String name,
    required String? categoryId,
    required String description,
    required double price,
    required String unit,
    required bool isAvailable,
    required bool isEnabled,
  }) async {
    await _client.from('products').update({
      'name': name,
      'category_id': categoryId,
      'description': description,
      'price': price,
      'unit': unit,
      'is_available': isAvailable,
      'is_enabled': isEnabled,
    }).eq('id', id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  @override
  Future<void> toggleProduct(String id, bool isEnabled) async {
    await _client.from('products').update({
      'is_enabled': isEnabled,
    }).eq('id', id);
  }

  @override
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await _client.from('products').update({
      'is_available': isAvailable,
    }).eq('id', id);
  }
}

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getCustomers({String? search}) async {
    var query = _client.from('customers').select();
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,phone.ilike.%$search%,address.ilike.%$search%');
    }
    final List<dynamic> res = await query.order('name', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    final res = await _client.from('customers').select().eq('id', id).maybeSingle();
    return res;
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerOrderHistory(String customerId) async {
    final List<dynamic> res = await _client
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .order('order_date', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> updateCustomer(String id, String name, String phone, String address) async {
    await _client.from('customers').update({
      'name': name,
      'phone': phone,
      'address': address,
    }).eq('id', id);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }
}

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getOrders({String? status, String? search}) async {
    var query = _client.from('orders').select('*, customers(name, phone)');
    
    if (status != null && status != 'All') {
      query = query.eq('status', status);
    }
    
    if (search != null && search.isNotEmpty) {
      query = query.or('order_number.ilike.%$search%');
    }
    
    final List<dynamic> res = await query.order('order_date', ascending: false);
    return res.map((order) {
      final Map<String, dynamic> mapped = Map.from(order);
      final cust = order['customers'] as Map<String, dynamic>?;
      mapped['customer_name'] = cust != null ? cust['name'] : 'N/A';
      mapped['customer_phone'] = cust != null ? cust['phone'] : 'N/A';
      return mapped;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    final res = await _client.from('orders').select('*, customers(name, phone)').eq('id', id).maybeSingle();
    if (res == null) return null;
    
    final Map<String, dynamic> mapped = Map.from(res);
    final cust = res['customers'] as Map<String, dynamic>?;
    mapped['customer_name'] = cust != null ? cust['name'] : 'N/A';
    mapped['customer_phone'] = cust != null ? cust['phone'] : 'N/A';
    return mapped;
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final List<dynamic> res = await _client.from('order_items').select().eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _client.from('orders').delete().eq('id', id);
  }
}

class SupabaseSettingsRepository implements SettingsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<Map<String, String>> getSettings() async {
    final List<dynamic> res = await _client.from('settings').select();
    return Map.fromEntries(res.map((r) => MapEntry(r['key'] as String, r['value'] as String)));
  }

  @override
  Future<void> updateSetting(String key, String value) async {
    await _client.from('settings').upsert({'key': key, 'value': value});
  }

  @override
  Future<void> resetDatabase() async {
    // Clear standard tables in remote Postgres
    await _client.from('order_items').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await _client.from('orders').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await _client.from('products').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await _client.from('categories').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }

  @override
  Future<void> seedDatabase() async {
    await DatabaseSeeder.seedSupabase(_client);
  }
}
