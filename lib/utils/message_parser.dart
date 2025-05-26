import 'package:topview/models/transaction.dart';

class MessageParser {
  static List<Transaction> parseMessage(String message, {String? clientId}) {
    // Check if the message is from STOCK_Alert
    if (!message.contains('BNo.') || !message.contains('Purchased') && !message.contains('Sold')) {
      return [];
    }

    try {
      // Extract broker number
      final brokerNumberMatch = RegExp(r'BNo\.(\d+)').firstMatch(message);
      final brokerNumber = brokerNumberMatch?.group(1) ?? '';

      // Extract transaction type
      final transactionType = message.contains('Purchased') ? 'Purchased' : 'Sold';
      
      // Extract date
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(message);
      final dateStr = dateMatch?.group(1) ?? '';
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();

      // Extract client ID (after the date)
      String extractedClientId = clientId ?? '';
      if (clientId == null) {
        final clientIdMatch = RegExp(r'\d{4}-\d{2}-\d{2}\s+(\d+)').firstMatch(message);
        extractedClientId = clientIdMatch?.group(1) ?? 'unknown';
      }

      // Extract stock information
      final stockInfoRegex = RegExp(r'\(([^)]+)\)');
      final stockInfoMatch = stockInfoRegex.firstMatch(message);
      
      if (stockInfoMatch == null) {
        return [];
      }
      
      final stocksInfo = stockInfoMatch.group(1) ?? '';
      final stocksSegments = stocksInfo.split(',');
      
      List<Transaction> transactions = [];
      
      for (var segment in stocksSegments) {
        final stockMatch = RegExp(r'([A-Z]+)\s+(\d+)\s+kitta\s+@\s+(\d+(?:,\d+)*)').firstMatch(segment.trim());
        
        if (stockMatch != null) {
          final symbol = stockMatch.group(1) ?? '';
          final quantity = int.tryParse(stockMatch.group(2) ?? '0') ?? 0;
          final priceStr = (stockMatch.group(3) ?? '0').replaceAll(',', '');
          final price = double.tryParse(priceStr) ?? 0.0;
          
          transactions.add(Transaction(
            clientId: extractedClientId,
            transactionType: transactionType,
            date: date,
            symbol: symbol,
            quantity: quantity,
            price: price,
            brokerNumber: brokerNumber,
          ));
        }
      }
        return transactions;
    } catch (e) {
      // Error parsing message - return empty list
      return [];
    }
  }
  
  // Extract client ID from message
  static String? extractClientId(String message) {
    final clientIdMatch = RegExp(r'\d{4}-\d{2}-\d{2}\s+(\d+)').firstMatch(message);
    return clientIdMatch?.group(1);
  }
}
