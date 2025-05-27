import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/models/share_data.dart'; // Import ShareData

class PortfolioService {
  // Calculate current holdings based on transactions
  static List<Holding> calculateHoldings(
    List<Transaction> transactions, 
    Map<String, ShareData> liveShareData, // Add live share data as a parameter
  ) {
    final Map<String, List<Transaction>> groupedBySymbol = {};
    for (var transaction in transactions) {
      if (!groupedBySymbol.containsKey(transaction.symbol)) {
        groupedBySymbol[transaction.symbol] = [];
      }
      groupedBySymbol[transaction.symbol]!.add(transaction);
    }

    List<Holding> holdings = [];
    groupedBySymbol.forEach((symbol, transactions) {
      // int totalSoldQuantity = 0; // Not directly needed for average buy price of current holdings

      // Calculate total quantity and total cost for BUY transactions only for current holdings
      // Sell transactions are handled by realized P/L
      List<Transaction> buyTransactions = transactions.where((t) => t.transactionType == 'Purchased').toList();
      List<Transaction> sellTransactions = transactions.where((t) => t.transactionType == 'Sold').toList();

      double averageBuyPrice = 0;

      int cumulatedBuyQuantity = 0;
      double cumulatedBuyCost = 0;
      for (var buyTx in buyTransactions) {
        cumulatedBuyQuantity += buyTx.quantity;
        cumulatedBuyCost += buyTx.quantity * buyTx.price;
      }

      int cumulatedSellQuantity = 0;
      for (var sellTx in sellTransactions) {
        cumulatedSellQuantity += sellTx.quantity;
      }

      int totalQuantity = cumulatedBuyQuantity - cumulatedSellQuantity;

      if (totalQuantity > 0) {
        if (cumulatedBuyQuantity > 0) {
          averageBuyPrice = cumulatedBuyCost / cumulatedBuyQuantity;
        }
        
        double currentInvestedValue = totalQuantity * averageBuyPrice;

        ShareData? currentShareInfo = liveShareData[symbol];
        // Use the new ltpNumeric getter from ShareData
        double ltp = currentShareInfo?.ltpNumeric ?? averageBuyPrice; // Use averageBuyPrice if LTP is not available
        String? percentChange = currentShareInfo?.percentChange;

        double currentValue = totalQuantity * ltp;
        double unrealizedPL = currentValue - currentInvestedValue;
        double unrealizedPLPercentage = (currentInvestedValue != 0 && currentInvestedValue.abs() > 0.001) ? (unrealizedPL / currentInvestedValue) * 100 : 0;

        holdings.add(Holding(
          symbol: symbol,
          quantity: totalQuantity,
          averageBuyPrice: averageBuyPrice,
          investedValue: currentInvestedValue,
          ltp: ltp,
          percentChange: percentChange,
          currentValue: currentValue,
          unrealizedPL: unrealizedPL,
          unrealizedPLPercentage: unrealizedPLPercentage,
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
