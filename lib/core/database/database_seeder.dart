import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static Future<void> seedAll() async {
    final db = await DatabaseHelper.instance.database;
    const uuid = Uuid();

    // 1. Check if categories already exist
    final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count > 0) return; // Database already has data, skip seeding

    // 2. Insert Categories
    final catVegetablesId = uuid.v4();
    final catFruitsId = uuid.v4();
    final catHerbsId = uuid.v4();
    final catDairyId = uuid.v4();

    final now = DateTime.now().toIso8601String();

    await db.insert('categories', {
      'id': catVegetablesId,
      'name': 'Vegetables',
      'is_enabled': 1,
      'created_at': now,
    });
    await db.insert('categories', {
      'id': catFruitsId,
      'name': 'Fruits',
      'is_enabled': 1,
      'created_at': now,
    });
    await db.insert('categories', {
      'id': catHerbsId,
      'name': 'Herbs & Seasoning',
      'is_enabled': 1,
      'created_at': now,
    });
    await db.insert('categories', {
      'id': catDairyId,
      'name': 'Dairy Products',
      'is_enabled': 1,
      'created_at': now,
    });

    // 3. Insert Products
    final List<Map<String, dynamic>> productsToSeed = [
      {
        'id': uuid.v4(),
        'name': 'Potato (Aloo)',
        'category_id': catVegetablesId,
        'description': 'Fresh local farm potatoes, perfect for daily cooking.',
        'price': 30.0,
        'unit': 'kg',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Tomato (Tamatar)',
        'category_id': catVegetablesId,
        'description': 'Juicy red vine-ripened tomatoes.',
        'price': 45.0,
        'unit': 'kg',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Onion (Pyaz)',
        'category_id': catVegetablesId,
        'description': 'Crispy pink onions from Nashik.',
        'price': 40.0,
        'unit': 'kg',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Apple (Shimla)',
        'category_id': catFruitsId,
        'description': 'Sweet and crunchy premium Shimla apples.',
        'price': 160.0,
        'unit': 'kg',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Banana (Robusta)',
        'category_id': catFruitsId,
        'description': 'Rich in potassium, ripe Robusta bananas.',
        'price': 60.0,
        'unit': 'dozen',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Coriander (Dhania)',
        'category_id': catHerbsId,
        'description': 'Fresh green coriander leaves bunch.',
        'price': 15.0,
        'unit': 'piece',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Ginger (Adrak)',
        'category_id': catHerbsId,
        'description': 'Spicy organic fresh ginger root.',
        'price': 180.0,
        'unit': 'kg',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Fresh Milk (500ml)',
        'category_id': catDairyId,
        'description': 'Pasteurized full cream milk packet.',
        'price': 32.0,
        'unit': 'packet',
        'is_available': 1,
      },
      {
        'id': uuid.v4(),
        'name': 'Paneer (200g)',
        'category_id': catDairyId,
        'description': 'Soft and fresh cottage cheese packet.',
        'price': 100.0,
        'unit': 'packet',
        'is_available': 1,
      },
    ];

    for (var p in productsToSeed) {
      await db.insert('products', {
        ...p,
        'image_path': '',
        'is_enabled': 1,
        'created_at': now,
      });
    }

    // 4. Insert Customers
    final cust1Id = uuid.v4();
    final cust2Id = uuid.v4();
    final cust3Id = uuid.v4();
    final cust4Id = uuid.v4();

    await db.insert('customers', {
      'id': cust1Id,
      'name': 'Rajesh Sharma',
      'phone': '9812345678',
      'email': 'rajesh@gmail.com',
      'address': 'Apt 201, Sunrise Heights, Kothrud, Pune',
      'password': 'password123',
      'is_logged_in': 0,
      'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    });

    await db.insert('customers', {
      'id': cust2Id,
      'name': 'Priya Patel',
      'phone': '9823456789',
      'email': 'priya.p@outlook.com',
      'address': 'Row House 3, Green Meadows, Baner, Pune',
      'password': 'password123',
      'is_logged_in': 0,
      'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    });

    await db.insert('customers', {
      'id': cust3Id,
      'name': 'Sunil Verma',
      'phone': '9834567890',
      'email': 'sunilv@yahoo.com',
      'address': 'Flat 405, Valley View Apartments, Hadapsar, Pune',
      'password': 'password123',
      'is_logged_in': 0,
      'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    });

    await db.insert('customers', {
      'id': cust4Id,
      'name': 'Ananya Rao',
      'phone': '9845678901',
      'email': 'ananya.rao@gmail.com',
      'address': 'Plot 12, Sahakar Nagar, Pune',
      'password': 'password123',
      'is_logged_in': 0,
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
    });

    // 5. Insert Orders & Order Items
    final order1Id = uuid.v4();
    final order2Id = uuid.v4();
    final order3Id = uuid.v4();
    final order4Id = uuid.v4();
    final order5Id = uuid.v4();

    // Fetch product lists to map IDs
    final dbProducts = await db.query('products');
    final pPotato = dbProducts.firstWhere((p) => p['name'] == 'Potato (Aloo)');
    final pTomato = dbProducts.firstWhere((p) => p['name'] == 'Tomato (Tamatar)');
    final pApple = dbProducts.firstWhere((p) => p['name'] == 'Apple (Shimla)');
    final pBanana = dbProducts.firstWhere((p) => p['name'] == 'Banana (Robusta)');
    final pPaneer = dbProducts.firstWhere((p) => p['name'] == 'Paneer (200g)');
    final pMilk = dbProducts.firstWhere((p) => p['name'] == 'Fresh Milk (500ml)');

    // Order 1: Pending, Rajesh Sharma
    await db.insert('orders', {
      'id': order1Id,
      'order_number': 'AB-1001',
      'customer_id': cust1Id,
      'customer_phone': '9812345678',
      'delivery_address': 'Apt 201, Sunrise Heights, Kothrud, Pune',
      'order_date': now,
      'status': 'Pending',
      'total_amount': 169.0,
    });
    // Potatoes (2 kg @ 30)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order1Id,
      'product_id': pPotato['id'],
      'product_name': pPotato['name'],
      'price': pPotato['price'],
      'quantity': 2.0,
      'unit': pPotato['unit'],
      'total_price': 60.0,
    });
    // Tomatoes (1 kg @ 45)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order1Id,
      'product_id': pTomato['id'],
      'product_name': pTomato['name'],
      'price': pTomato['price'],
      'quantity': 1.0,
      'unit': pTomato['unit'],
      'total_price': 45.0,
    });
    // Milk (2 packets @ 32)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order1Id,
      'product_id': pMilk['id'],
      'product_name': pMilk['name'],
      'price': pMilk['price'],
      'quantity': 2.0,
      'unit': pMilk['unit'],
      'total_price': 64.0,
    });

    // Order 2: Delivered, Priya Patel
    await db.insert('orders', {
      'id': order2Id,
      'order_number': 'AB-1002',
      'customer_id': cust2Id,
      'customer_phone': '9823456789',
      'delivery_address': 'Row House 3, Green Meadows, Baner, Pune',
      'order_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'status': 'Delivered',
      'total_amount': 320.0,
    });
    // Apple (1 kg @ 160)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order2Id,
      'product_id': pApple['id'],
      'product_name': pApple['name'],
      'price': pApple['price'],
      'quantity': 1.0,
      'unit': pApple['unit'],
      'total_price': 160.0,
    });
    // Banana (1 dozen @ 60)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order2Id,
      'product_id': pBanana['id'],
      'product_name': pBanana['name'],
      'price': pBanana['price'],
      'quantity': 1.0,
      'unit': pBanana['unit'],
      'total_price': 60.0,
    });
    // Paneer (1 packet @ 100)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order2Id,
      'product_id': pPaneer['id'],
      'product_name': pPaneer['name'],
      'price': pPaneer['price'],
      'quantity': 1.0,
      'unit': pPaneer['unit'],
      'total_price': 100.0,
    });

    // Order 3: Preparing, Sunil Verma
    await db.insert('orders', {
      'id': order3Id,
      'order_number': 'AB-1003',
      'customer_id': cust3Id,
      'customer_phone': '9834567890',
      'delivery_address': 'Flat 405, Valley View Apartments, Hadapsar, Pune',
      'order_date': now,
      'status': 'Preparing',
      'total_amount': 164.0,
    });
    // Milk (2 packets @ 32)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order3Id,
      'product_id': pMilk['id'],
      'product_name': pMilk['name'],
      'price': pMilk['price'],
      'quantity': 2.0,
      'unit': pMilk['unit'],
      'total_price': 64.0,
    });
    // Paneer (1 packet @ 100)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order3Id,
      'product_id': pPaneer['id'],
      'product_name': pPaneer['name'],
      'price': pPaneer['price'],
      'quantity': 1.0,
      'unit': pPaneer['unit'],
      'total_price': 100.0,
    });

    // Order 4: Out for Delivery, Ananya Rao
    await db.insert('orders', {
      'id': order4Id,
      'order_number': 'AB-1004',
      'customer_id': cust4Id,
      'customer_phone': '9845678901',
      'delivery_address': 'Plot 12, Sahakar Nagar, Pune',
      'order_date': now,
      'status': 'Out for Delivery',
      'total_amount': 240.0,
    });
    // Tomato (2 kg @ 45)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order4Id,
      'product_id': pTomato['id'],
      'product_name': pTomato['name'],
      'price': pTomato['price'],
      'quantity': 2.0,
      'unit': pTomato['unit'],
      'total_price': 90.0,
    });
    // Potato (5 kg @ 30)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order4Id,
      'product_id': pPotato['id'],
      'product_name': pPotato['name'],
      'price': pPotato['price'],
      'quantity': 5.0,
      'unit': pPotato['unit'],
      'total_price': 150.0,
    });

    // Order 5: Cancelled, Rajesh Sharma
    await db.insert('orders', {
      'id': order5Id,
      'order_number': 'AB-1005',
      'customer_id': cust1Id,
      'customer_phone': '9812345678',
      'delivery_address': 'Apt 201, Sunrise Heights, Kothrud, Pune',
      'order_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'status': 'Cancelled',
      'total_amount': 320.0,
    });
    // Apple (2 kg @ 160)
    await db.insert('order_items', {
      'id': uuid.v4(),
      'order_id': order5Id,
      'product_id': pApple['id'],
      'product_name': pApple['name'],
      'price': pApple['price'],
      'quantity': 2.0,
      'unit': pApple['unit'],
      'total_price': 320.0,
    });
  }

  static Future<void> seedSupabase(SupabaseClient client) async {
    // 1. Check if categories already exist
    final countRes = await client.from('categories').select('id');
    if (countRes.isNotEmpty) return; // Skip if already seeded

    const uuid = Uuid();
    final catVegetablesId = uuid.v4();
    final catFruitsId = uuid.v4();
    final catHerbsId = uuid.v4();
    final catDairyId = uuid.v4();

    final now = DateTime.now().toIso8601String();

    await client.from('categories').insert([
      {'id': catVegetablesId, 'name': 'Vegetables', 'is_enabled': true, 'created_at': now},
      {'id': catFruitsId, 'name': 'Fruits', 'is_enabled': true, 'created_at': now},
      {'id': catHerbsId, 'name': 'Herbs & Seasoning', 'is_enabled': true, 'created_at': now},
      {'id': catDairyId, 'name': 'Dairy Products', 'is_enabled': true, 'created_at': now},
    ]);

    // Insert Products
    final List<Map<String, dynamic>> productsToSeed = [
      {
        'id': uuid.v4(),
        'name': 'Potato (Aloo)',
        'category_id': catVegetablesId,
        'description': 'Fresh local farm potatoes, perfect for daily cooking.',
        'price': 30.0,
        'unit': 'kg',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Tomato (Tamatar)',
        'category_id': catVegetablesId,
        'description': 'Juicy red vine-ripened tomatoes.',
        'price': 45.0,
        'unit': 'kg',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Onion (Pyaz)',
        'category_id': catVegetablesId,
        'description': 'Crispy pink onions from Nashik.',
        'price': 40.0,
        'unit': 'kg',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Apple (Shimla)',
        'category_id': catFruitsId,
        'description': 'Sweet and crunchy premium Shimla apples.',
        'price': 160.0,
        'unit': 'kg',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Banana (Robusta)',
        'category_id': catFruitsId,
        'description': 'Rich in potassium, ripe Robusta bananas.',
        'price': 60.0,
        'unit': 'dozen',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Coriander (Dhania)',
        'category_id': catHerbsId,
        'description': 'Fresh green coriander leaves bunch.',
        'price': 15.0,
        'unit': 'piece',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Ginger (Adrak)',
        'category_id': catHerbsId,
        'description': 'Spicy organic fresh ginger root.',
        'price': 180.0,
        'unit': 'kg',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Fresh Milk (500ml)',
        'category_id': catDairyId,
        'description': 'Pasteurized full cream milk packet.',
        'price': 32.0,
        'unit': 'packet',
        'is_available': true,
      },
      {
        'id': uuid.v4(),
        'name': 'Paneer (200g)',
        'category_id': catDairyId,
        'description': 'Soft and fresh cottage cheese packet.',
        'price': 100.0,
        'unit': 'packet',
        'is_available': true,
      },
    ];

    for (var p in productsToSeed) {
      await client.from('products').insert({
        ...p,
        'image_path': '',
        'is_enabled': true,
        'created_at': now,
      });
    }

    // Settings
    await client.from('settings').upsert([
      {'key': 'store_name', 'value': 'ApliBhaji Store'},
      {'key': 'store_phone', 'value': '+91 9876543210'},
      {'key': 'store_address', 'value': 'Main Bazar, Pune, Maharashtra'},
      {'key': 'delivery_charge', 'value': '30'},
      {'key': 'free_delivery_threshold', 'value': '300'},
    ]);
  }
}
