import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/transaction.dart';
import 'database_service.dart';

class TransactionDAO {
  static Future<sqflite.Database> get _db async => await DatabaseService.database;

  // Insert a new transaction
  static Future<int> insertTransaction(Transaction transaction) async {
    final db = await _db;
    return await db.insert(
      DatabaseService.transactionsTable,
      _transactionToMap(transaction),
      conflictAlgorithm: sqflite.ConflictAlgorithm.ignore, // Ignore duplicates
    );
  }

  // Insert multiple transactions
  static Future<List<int>> insertTransactions(List<Transaction> transactions) async {
    final db = await _db;
    final batch = db.batch();
    
    for (var transaction in transactions) {
      batch.insert(
        DatabaseService.transactionsTable,
        _transactionToMap(transaction),
        conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
      );
    }
    
    final results = await batch.commit();
    return results.cast<int>();
  }

  // Get all transactions for a client
  static Future<List<Transaction>> getTransactionsByClientId(String clientId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.transactionsTable,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  // Get all transactions
  static Future<List<Transaction>> getAllTransactions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.transactionsTable,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  // Search transactions by symbol, type, or date range
  static Future<List<Transaction>> searchTransactions({
    String? clientId,
    String? symbol,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (clientId != null) {
      whereClause += 'client_id = ?';
      whereArgs.add(clientId);
    }
    
    if (symbol != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'symbol LIKE ?';
      whereArgs.add('%$symbol%');
    }
    
    if (transactionType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'transaction_type = ?';
      whereArgs.add(transactionType);
    }
    
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.transactionsTable,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
  }

  // Get latest transaction for a client
  static Future<Transaction?> getLatestTransaction(String clientId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.transactionsTable,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToTransaction(maps.first);
  }

  // Delete all transactions
  static Future<int> deleteAllTransactions() async {
    final db = await _db;
    return await db.delete(DatabaseService.transactionsTable);
  }

  // Delete transactions for a specific client
  static Future<int> deleteTransactionsByClientId(String clientId) async {
    final db = await _db;
    return await db.delete(
      DatabaseService.transactionsTable,
      where: 'client_id = ?',
      whereArgs: [clientId],
    );
  }

  // Get transaction count by client
  static Future<int> getTransactionCount(String clientId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseService.transactionsTable} WHERE client_id = ?',
      [clientId],
    );
    return result.first['count'] as int;
  }

  // Helper methods
  static Map<String, dynamic> _transactionToMap(Transaction transaction) {
    return {
      'client_id': transaction.clientId,
      'transaction_type': transaction.transactionType,
      'date': transaction.date.toIso8601String(),
      'symbol': transaction.symbol,
      'quantity': transaction.quantity,
      'price': transaction.price,
      'broker_number': transaction.brokerNumber,
    };
  }

  static Transaction _mapToTransaction(Map<String, dynamic> map) {
    return Transaction(
      clientId: map['client_id'],
      transactionType: map['transaction_type'],
      date: DateTime.parse(map['date']),
      symbol: map['symbol'],
      quantity: map['quantity'],
      price: map['price'],
      brokerNumber: map['broker_number'],
    );
  }
}
