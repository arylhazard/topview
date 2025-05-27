import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';

class HoldingsPage extends StatelessWidget {
  const HoldingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holdings'),
        actions: [
          Consumer<PortfolioProvider>(
            builder: (context, provider, child) {
              if (provider.isShareDataLoading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  provider.fetchLiveShareData(forceScrape: true); // Allow manual refresh
                },
                tooltip: 'Refresh Market Data',
              );
            }
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.holdings.isEmpty && !provider.isShareDataLoading) {
            return const Center(
              child: Text('No holdings found. Add transactions or check client ID.'),
            );
          }
          if (provider.isShareDataLoading && provider.holdings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          String? subtitleText;
          if (provider.shareDataDate != null) {
            subtitleText = 'Market Data As Of: ${provider.shareDataDate}';
            if (provider.shareDataError != null) {
              subtitleText += ' (Error: ${provider.shareDataError})';
            }
          } else if (provider.shareDataError != null) {
            subtitleText = 'Market Data Error: ${provider.shareDataError}';
          }

          return Column(
            children: [
              if (subtitleText != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    subtitleText,
                    style: TextStyle(fontSize: 12, color: provider.shareDataError != null ? Colors.orange : Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.holdings.length,
                  itemBuilder: (context, index) {
                    final holding = provider.holdings[index];
                    // Values are now directly from the Holding object, calculated with LTP
                    final ltp = holding.ltp ?? holding.averageBuyPrice; // Fallback to avg if LTP is null
                    final percentChangeText = holding.percentChange ?? 'N/A';
                    final unrealizedPL = holding.unrealizedPL;
                    final unrealizedPLPercentage = holding.unrealizedPLPercentage;
                    
                    Color plColor = unrealizedPL > 0.001 ? Colors.green : (unrealizedPL < -0.001 ? Colors.red : Colors.grey);
                    IconData trendIcon = Icons.remove;
                    if (percentChangeText.contains('-')) trendIcon = Icons.arrow_downward;
                    else if (double.tryParse(percentChangeText.replaceAll('%', '')) != null && 
                             double.parse(percentChangeText.replaceAll('%', '')) > 0) trendIcon = Icons.arrow_upward;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  holding.symbol,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${holding.quantity} shares',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildDetailsRow('Avg. Buy Price', '₹${holding.averageBuyPrice.toStringAsFixed(2)}'),
                            _buildDetailsRow(
                              'LTP', 
                              '₹${ltp.toStringAsFixed(2)}', 
                              trailingWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(trendIcon, size: 16, color: plColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    percentChangeText,
                                    style: TextStyle(color: plColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ),
                            _buildDetailsRow('Invested Value', '₹${holding.investedValue.toStringAsFixed(2)}'),
                            _buildDetailsRow('Current Value', '₹${holding.currentValue.toStringAsFixed(2)}', textColor: plColor),
                            _buildDetailsRow(
                              'Unrealized P/L', 
                              '₹${unrealizedPL.toStringAsFixed(2)} (${unrealizedPLPercentage.toStringAsFixed(2)}%)',
                              textColor: plColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDetailsRow(String label, String value, {Color? textColor, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ]
            ],
          ),
        ],
      ),
    );
  }
}
