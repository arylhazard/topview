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
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.holdings.isEmpty) {
            return const Center(
              child: Text('No holdings found'),
            );
          }
          
          return ListView.builder(
            itemCount: provider.holdings.length,
            itemBuilder: (context, index) {
              final holding = provider.holdings[index];
              final profitLoss = holding.currentValue - holding.investedValue;
              final profitLossPercentage = (profitLoss / holding.investedValue) * 100;
              
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
                      _buildDetailsRow('Average Buy Price', '₹${holding.averageBuyPrice.toStringAsFixed(2)}'),
                      _buildDetailsRow('Current Price', '₹${(holding.currentValue / holding.quantity).toStringAsFixed(2)}'),
                      _buildDetailsRow('Invested Value', '₹${holding.investedValue.toStringAsFixed(2)}'),
                      _buildDetailsRow('Current Value', '₹${holding.currentValue.toStringAsFixed(2)}'),
                      _buildDetailsRow(
                        'Profit/Loss', 
                        '₹${profitLoss.toStringAsFixed(2)} (${profitLossPercentage.toStringAsFixed(2)}%)',
                        textColor: profitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildDetailsRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
