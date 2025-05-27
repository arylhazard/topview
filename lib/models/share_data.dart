class ShareData {
  final String symbol;
  final String ltp; // Last Traded Price
  final String percentChange;

  // Define constants for indices at the class level to be accessible externally if needed
  static const int symbolIndex = 1;
  static const int ltpIndex = 7;
  static const int percentChangeIndex = 17;

  ShareData({
    required this.symbol,
    required this.ltp,
    required this.percentChange,
  });

  // Getter to parse LTP string to double
  double get ltpNumeric {
    return double.tryParse(ltp.replaceAll(',', '')) ?? 0.0;
  }

  // Indices based on ShareSansar table structure (actual, 0-indexed):
  // 0: S.No, 1: Symbol, 2: Conf., 3: Open, 4: High, 5: Low, 6: Close, 
  // 7: LTP, 8: Close - LTP, 9: Close - LTP %, ..., 17: Diff %
  // We need Symbol (1), LTP (7), and Diff % (17) for percentChange
  factory ShareData.fromRow(List<String> cells) {
    if (cells.length <= percentChangeIndex) { // Now uses class-level constant
      print("ShareData.fromRow: Not enough cells for data - expected at least ${percentChangeIndex + 1}, got ${cells.length}. Symbol: ${cells.length > symbolIndex ? cells[symbolIndex].trim() : 'N/A'}");
      return ShareData(
        symbol: cells.length > symbolIndex ? cells[symbolIndex].trim() : 'ErrorInSymbol',
        ltp: 'N/A',
        percentChange: 'N/A',
      );
    }
    return ShareData(
      symbol: cells[symbolIndex].trim(),
      ltp: cells[ltpIndex].trim(), // Corrected index for LTP to 7
      percentChange: cells[percentChangeIndex].trim(), // Corrected index for %Change to 17 (Diff %)
    );
  }

  Map<String, dynamic> toMapForDb() {
    return {
      'symbol': symbol,
      'ltp': ltpNumeric, // Store the numeric LTP in DB
      'percent_change': percentChange,
    };
  }

  factory ShareData.fromDbMap(Map<String, dynamic> map) {
    return ShareData(
      symbol: map['symbol'] as String,
      ltp: map['ltp']?.toString() ?? 'N/A',
      percentChange: map['percent_change'] as String? ?? 'N/A',
    );
  }

  @override
  String toString() {
    return 'ShareData(symbol: $symbol, ltp: $ltp, percentChange: $percentChange)';
  }

  // Determine positive/negative based on percentChange string
  bool get isPositiveChange {
    // Check if percentChange string starts with a number and doesn't have a minus
    // and is not "0.00" or similar neutral values.
    // A more robust way would be to parse pointChange if available, but we removed it.
    // For now, we assume any non-negative, non-zero % change is positive.
    final cleanedPercent = percentChange.replaceAll('%', '').trim();
    final numericPercent = double.tryParse(cleanedPercent);
    return numericPercent != null && numericPercent > 0;
  }

  bool get isNegativeChange {
    final cleanedPercent = percentChange.replaceAll('%', '').trim();
    final numericPercent = double.tryParse(cleanedPercent);
    return numericPercent != null && numericPercent < 0;
  }
}
