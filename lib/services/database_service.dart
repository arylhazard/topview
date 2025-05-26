import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'portfolio.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String transactionsTable = 'transactions';
  static const String clientsTable = 'clients';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE $transactionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        date TEXT NOT NULL,
        symbol TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        broker_number TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(client_id, transaction_type, date, symbol, quantity, price, broker_number)
      )
    ''');

    // Create clients table
    await db.execute('''
      CREATE TABLE $clientsTable (
        id TEXT PRIMARY KEY,
        name TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_transaction_date TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_transactions_client_id ON $transactionsTable(client_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_transactions_symbol ON $transactionsTable(symbol)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_transactions_date ON $transactionsTable(date)
    ''');
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
