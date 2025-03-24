import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topview/models/transaction.dart';

class StorageService {
  static const String _transactionsKey = 'transactions';

  // Save transactions to SharedPreferences
  static Future<bool> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing transactions
    List<Transaction> existingTransactions = await getTransactions();
    
    // Filter out duplicates by checking if a similar transaction already exists
    List<Transaction> uniqueTransactions = [];
    
    for (var newTransaction in transactions) {
      bool isDuplicate = existingTransactions.any((existing) => 
        existing.clientId == newTransaction.clientId &&
        existing.symbol == newTransaction.symbol &&
        existing.transactionType == newTransaction.transactionType &&
        existing.date.isAtSameMomentAs(newTransaction.date) &&
        existing.quantity == newTransaction.quantity &&
        existing.price == newTransaction.price &&
        existing.brokerNumber == newTransaction.brokerNumber
      );
      
      if (!isDuplicate) {
        uniqueTransactions.add(newTransaction);
      }
    }
    
    // Only add non-duplicate transactions
    if (uniqueTransactions.isEmpty) {
      return true; // Nothing new to add
    }
    
    existingTransactions.addAll(uniqueTransactions);
    
    // Convert to JSON list
    final jsonList = existingTransactions.map((t) => jsonEncode(t.toJson())).toList();
    
    // Save to SharedPreferences
    return await prefs.setStringList(_transactionsKey, jsonList);
  }

  // Get all transactions from SharedPreferences
  static Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_transactionsKey) ?? [];
    
    return jsonList
        .map((jsonStr) => Transaction.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  // Get transactions for a specific client ID
  static Future<List<Transaction>> getTransactionsByClientId(String clientId) async {
    final transactions = await getTransactions();
    return transactions.where((t) => t.clientId == clientId).toList();
  }

  // Clear all transactions (useful for testing)
  static Future<bool> clearTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_transactionsKey);
  }
}
