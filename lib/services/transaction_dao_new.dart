import 'package:sqflite/sqflite.dart' as sqflite;
import '../models/transaction.dart';
import 'database_service.dart';

class TransactionDAO {
  static Future<sqflite.Database> get _db async => await DatabaseService.database;

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

  // Get latest transaction for a client
  static Future<Transaction?> getLatestTransaction(String clientId) async {
    final db = await _db;
    final List<Map<String, dynamic>> result = await db.query(
      DatabaseService.transactionsTable,
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return _mapToTransaction(result.first);
    }
    return null;
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

  // Delete all transactions
  static Future<int> deleteAllTransactions() async {
    final db = await _db;
    return await db.delete(DatabaseService.transactionsTable);
  }

  // Search transactions with filters
  static Future<List<Transaction>> searchTransactions({
    required String clientId,
    String? symbol,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    
    String whereClause = 'client_id = ?';
    List<dynamic> whereArgs = [clientId];
    
    if (symbol != null) {
      whereClause += ' AND symbol LIKE ?';
      whereArgs.add('%$symbol%');
    }
    
    if (transactionType != null) {
      whereClause += ' AND transaction_type = ?';
      whereArgs.add(transactionType);
    }
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    final maps = await db.query(
      DatabaseService.transactionsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    
    return List.generate(maps.length, (i) => _mapToTransaction(maps[i]));
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
