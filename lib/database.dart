
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class POSDatabase {
  // ...existing code...
  static Future<int> updateFarmService(Map<String, dynamic> service) async {
    final db = await database;
    if (!service.containsKey('id')) throw Exception('Service id required for update');
    int id = service['id'];
    final updateMap = Map<String, dynamic>.from(service)..remove('id');
    return await db.update('farm_services', updateMap, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteFarmService(int id) async {
    final db = await database;
    return await db.delete('farm_services', where: 'id = ?', whereArgs: [id]);
  }
  static Future<void> updateFarmServiceStatus(int id, String status) async {
    final db = await database;
    await db.update('farm_services', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('pos.db');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add image column to products if missing
      await db.execute('ALTER TABLE products ADD COLUMN image TEXT;');
    }
    // Ensure expiry column exists
    try {
      await db.execute('ALTER TABLE products ADD COLUMN expiry TEXT;');
    } catch (e) {
      // Ignore if already exists
    }
  }

  static Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        image TEXT,
        buyingPrice REAL,
        sellingPrice REAL,
        quantity INTEGER,
        minStock INTEGER,
        expiry TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        idNumber TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        customerId INTEGER,
        quantity INTEGER,
        total REAL,
        date TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE farm_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        due TEXT,
        amount REAL,
        status TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        quantity INTEGER,
        expiry TEXT
      );
    ''');
  }

  // Utility to clear all tables for a fresh POS
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('products');
    await db.delete('customers');
    await db.delete('sales');
    await db.delete('farm_services');
    await db.delete('inventory');
  }

  // Example CRUD for products
  static Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    // Ensure buyingPrice and sellingPrice are present
    if (!product.containsKey('buyingPrice') || !product.containsKey('sellingPrice')) {
      throw Exception('Product must have buyingPrice and sellingPrice');
    }
    // Upsert logic: update if exists, else insert
    final existing = await db.query('products', where: 'id = ?', whereArgs: [product['id']]);
    if (existing.isNotEmpty) {
      int id = product['id'];
      final updateMap = Map<String, dynamic>.from(product)..remove('id');
      return await db.update('products', updateMap, where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert('products', product);
    }
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  static Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    if (!product.containsKey('id')) throw Exception('Product id required for update');
    int id = product['id'];
    final updateMap = Map<String, dynamic>.from(product)..remove('id');
    return await db.update('products', updateMap, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Example CRUD for customers
  static Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    // Upsert logic: update if exists, else insert
    final existing = await db.query('customers', where: 'id = ?', whereArgs: [customer['id']]);
    if (existing.isNotEmpty) {
      int id = customer['id'];
      final updateMap = Map<String, dynamic>.from(customer)..remove('id');
      return await db.update('customers', updateMap, where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert('customers', customer);
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers');
  }

  // Example CRUD for sales
  static Future<int> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    // Ensure productId exists in products table
    final productId = sale['productId'];
    final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (product.isEmpty) {
      throw Exception('Product not found in inventory for sale');
    }
    // Upsert logic: update if exists, else insert
    final existing = await db.query('sales', where: 'id = ?', whereArgs: [sale['id']]);
    if (existing.isNotEmpty) {
      // Update existing sale
      return await db.update('sales', sale, where: 'id = ?', whereArgs: [sale['id']]);
    } else {
      // Insert new sale
      return await db.insert('sales', sale);
    }
  }

  static Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    return await db.query('sales');
  }

  // Example CRUD for farm services
  static Future<int> insertFarmService(Map<String, dynamic> service) async {
    final db = await database;
    // Upsert logic: update if exists, else insert
    final existing = await db.query('farm_services', where: 'id = ?', whereArgs: [service['id']]);
    if (existing.isNotEmpty) {
      int id = service['id'];
      final updateMap = Map<String, dynamic>.from(service)..remove('id');
      return await db.update('farm_services', updateMap, where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert('farm_services', service);
    }
  }

  static Future<List<Map<String, dynamic>>> getFarmServices() async {
    final db = await database;
    return await db.query('farm_services');
  }

  // Example CRUD for inventory
  static Future<int> insertInventory(Map<String, dynamic> inventory) async {
    final db = await database;
    // Upsert logic: update if exists, else insert
    final existing = await db.query('inventory', where: 'id = ?', whereArgs: [inventory['id']]);
    if (existing.isNotEmpty) {
      int id = inventory['id'];
      final updateMap = Map<String, dynamic>.from(inventory)..remove('id');
      return await db.update('inventory', updateMap, where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert('inventory', inventory);
    }
  }

  static Future<List<Map<String, dynamic>>> getInventory() async {
    final db = await database;
    return await db.query('inventory');
  }
}
