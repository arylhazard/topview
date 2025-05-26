import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';

class PortfolioService {
  // Calculate current holdings based on transactions
  static List<Holding> calculateHoldings(List<Transaction> transactions) {
    // Group transactions by symbol
    final Map<String, List<Transaction>> groupedBySymbol = {};
    
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }
    
    // Calculate holdings for each symbol
    List<Holding> holdings = [];
      groupedBySymbol.forEach((symbol, transactions) {
      int totalQuantity = 0;
      double totalValue = 0;
      int totalSoldQuantity = 0;
      
      for (var transaction in transactions) {
        if (transaction.transactionType == 'Purchased') {
          totalQuantity += transaction.quantity;
          totalValue += transaction.quantity * transaction.price;
        } else if (transaction.transactionType == 'Sold') {
          totalQuantity -= transaction.quantity;
          totalSoldQuantity += transaction.quantity;
        }
      }
        // Only include if we still have shares
      if (totalQuantity > 0) {
        final averageBuyPrice = double.parse((totalValue / (totalQuantity + totalSoldQuantity)).toStringAsFixed(2));
        final currentValue = double.parse((totalQuantity * averageBuyPrice).toStringAsFixed(2)); // Using avg price as current price for now
        
        holdings.add(Holding(
          symbol: symbol,
          quantity: totalQuantity,
          averageBuyPrice: averageBuyPrice,
          currentValue: currentValue,
          investedValue: double.parse((totalQuantity * averageBuyPrice).toStringAsFixed(2)),
        ));
      }
    });
    
    return holdings;
  }
  
  // Calculate realized profit/loss
  static double calculateRealizedProfitLoss(List<Transaction> transactions) {
    double realizedPL = 0;
    
    // Group transactions by symbol
    final Map<String, List<Transaction>> groupedBySymbol = {};
    
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }
    
    groupedBySymbol.forEach((symbol, transactions) {
      List<Transaction> buys = [];
      
      // First pass: collect all buys
      for (var transaction in transactions) {
        if (transaction.transactionType == 'Purchased') {
          buys.add(transaction);
        }
      }
      
      // Second pass: process sells using FIFO (First In, First Out)
      for (var transaction in transactions) {
        if (transaction.transactionType == 'Sold') {
          int remainingSellQuantity = transaction.quantity;
          
          while (remainingSellQuantity > 0 && buys.isNotEmpty) {
            var oldestBuy = buys.first;
            int buyQuantityToUse = oldestBuy.quantity < remainingSellQuantity ? 
                oldestBuy.quantity : remainingSellQuantity;
                  // Calculate profit/loss for this portion
            double buyValue = buyQuantityToUse * oldestBuy.price;
            double sellValue = buyQuantityToUse * transaction.price;
            realizedPL += (sellValue - buyValue);
            
            // Update remaining quantities
            remainingSellQuantity -= buyQuantityToUse;
            
            if (buyQuantityToUse == oldestBuy.quantity) {
              buys.removeAt(0); // Remove fully used buy transaction
            } else {
              // Update the quantity of the buy transaction
              buys[0] = Transaction(
                clientId: oldestBuy.clientId,
                transactionType: oldestBuy.transactionType,
                date: oldestBuy.date,
                symbol: oldestBuy.symbol,
                quantity: oldestBuy.quantity - buyQuantityToUse,
                price: oldestBuy.price,
                brokerNumber: oldestBuy.brokerNumber,
              );
            }
          }
        }
      }    });
    
    return double.parse(realizedPL.toStringAsFixed(2));
  }
  
  // Calculate break-even portfolio value
  static double calculateBreakEvenValue(List<Transaction> transactions, List<Holding> holdings) {
    double totalInvested = 0;
    
    // Sum the total amount invested across all purchases
    for (var transaction in transactions) {
      if (transaction.transactionType == 'Purchased') {
        totalInvested += transaction.quantity * transaction.price;      } else if (transaction.transactionType == 'Sold') {
        totalInvested -= transaction.quantity * transaction.price;
      }
    }
    
    // The break-even value is what the portfolio must reach to recover the investment
    return double.parse(totalInvested.toStringAsFixed(2));
  }
}
