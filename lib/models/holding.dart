class Holding {
  final String symbol;
  final int quantity;
  final double averageBuyPrice;
  final double currentValue;
  final double investedValue;
  final double profitLoss;
  final double profitLossPercentage;

  Holding({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
    required this.currentValue,
    required this.investedValue,
    this.profitLoss = 0,
    this.profitLossPercentage = 0,
  });
}
