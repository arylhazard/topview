import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/share_data.dart'; // Import ShareData model

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'portfolio.db';
  static const int _databaseVersion = 2; // Incremented from 1 to 2

  // Table names
  static const String transactionsTable = 'transactions';
  static const String clientsTable = 'clients';
  static const String dailyShareDataTable = 'daily_share_data'; // New table

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

    // Create daily_share_data table
    await db.execute('''
      CREATE TABLE $dailyShareDataTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT NOT NULL,
        ltp REAL NOT NULL,            -- Last Traded Price
        percent_change TEXT NOT NULL,
        data_date TEXT NOT NULL,      -- The date for which this data is valid
        scraped_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(symbol, data_date) -- Ensure only one entry per symbol per day
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_daily_share_data_symbol ON $dailyShareDataTable(symbol)
    ''');
    await db.execute('''
      CREATE INDEX idx_daily_share_data_date ON $dailyShareDataTable(data_date)
    ''');
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { // Example: If upgrading from version 1 to 2
        await db.execute('''
          CREATE TABLE $dailyShareDataTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL,
            ltp REAL NOT NULL,
            percent_change TEXT NOT NULL,
            data_date TEXT NOT NULL,
            scraped_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(symbol, data_date)
          )
        ''');
        await db.execute('CREATE INDEX idx_daily_share_data_symbol ON $dailyShareDataTable(symbol)');
        await db.execute('CREATE INDEX idx_daily_share_data_date ON $dailyShareDataTable(data_date)');
    }
    // Add more upgrade steps as needed for future versions
  }

  // --- CRUD for DailyShareData ---

  static Future<void> insertOrUpdateShareData(ShareData shareData, String siteDate) async {
    final db = await database;
    Map<String, dynamic> row = shareData.toMapForDb();
    row['data_date'] = siteDate; // Add the date from the website

    await db.insert(
      dailyShareDataTable,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace, // Replaces if symbol+data_date conflict
    );
  }

  static Future<void> bulkInsertOrUpdateShareData(List<ShareData> shareDataList, String siteDate) async {
    final db = await database;
    Batch batch = db.batch();
    for (var shareData in shareDataList) {
      Map<String, dynamic> row = shareData.toMapForDb();
      row['data_date'] = siteDate;
      batch.insert(
        dailyShareDataTable,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<ShareData>> getShareDataByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      dailyShareDataTable,
      where: 'data_date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) {
      return ShareData.fromDbMap(maps[i]);
    });
  }

  static Future<ShareData?> getLatestShareDataForSymbol(String symbol) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      dailyShareDataTable,
      where: 'symbol = ?',
      whereArgs: [symbol],
      orderBy: 'data_date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ShareData.fromDbMap(maps.first);
    }
    return null;
  }

  static Future<String?> getLatestStoredDataDate() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      dailyShareDataTable,
      columns: ['MAX(data_date) as latest_date'],
    );
    if (result.isNotEmpty && result.first['latest_date'] != null) {
      return result.first['latest_date'] as String?;
    }
    return null;
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
