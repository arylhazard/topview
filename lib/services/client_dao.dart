import 'package:sqflite/sqflite.dart';
import '../models/client.dart';
import 'database_service.dart';

class ClientDAO {
  static Future<Database> get _db async => await DatabaseService.database;

  // Insert or update a client
  static Future<int> insertOrUpdateClient(Client client) async {
    final db = await _db;
    return await db.insert(
      DatabaseService.clientsTable,
      _clientToMap(client),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all clients
  static Future<List<Client>> getAllClients() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.clientsTable,
      orderBy: 'last_transaction_date DESC',
    );

    return List.generate(maps.length, (i) => _mapToClient(maps[i]));
  }

  // Get client by ID
  static Future<Client?> getClientById(String id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.clientsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToClient(maps.first);
  }

  // Update client's last transaction date
  static Future<int> updateLastTransactionDate(String clientId, DateTime date) async {
    final db = await _db;
    return await db.update(
      DatabaseService.clientsTable,
      {'last_transaction_date': date.toIso8601String()},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  // Delete a client
  static Future<int> deleteClient(String id) async {
    final db = await _db;
    return await db.delete(
      DatabaseService.clientsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all clients
  static Future<int> deleteAllClients() async {
    final db = await _db;
    return await db.delete(DatabaseService.clientsTable);
  }

  // Helper methods
  static Map<String, dynamic> _clientToMap(Client client) {
    return {
      'id': client.id,
      'name': client.name,
      'created_at': client.createdAt.toIso8601String(),
      'last_transaction_date': client.lastTransactionDate?.toIso8601String(),
    };
  }

  static Client _mapToClient(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      lastTransactionDate: map['last_transaction_date'] != null
          ? DateTime.parse(map['last_transaction_date'])
          : null,
    );
  }
}
