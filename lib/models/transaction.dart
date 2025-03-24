class Transaction {
  final String clientId;
  final String transactionType; // "Purchased" or "Sold"
  final DateTime date;
  final String symbol;
  final int quantity;
  final double price;
  final String brokerNumber;

  Transaction({
    required this.clientId,
    required this.transactionType,
    required this.date,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.brokerNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'transactionType': transactionType,
      'date': date.toIso8601String(),
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'brokerNumber': brokerNumber,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      clientId: json['clientId'],
      transactionType: json['transactionType'],
      date: DateTime.parse(json['date']),
      symbol: json['symbol'],
      quantity: json['quantity'],
      price: json['price'],
      brokerNumber: json['brokerNumber'],
    );
  }
}
