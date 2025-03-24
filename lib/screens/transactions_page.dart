import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.transactions.isEmpty) {
            return const Center(
              child: Text('No transactions found'),
            );
          }
          
          // Sort transactions with newest first
          final sortedTransactions = List.from(provider.transactions)
            ..sort((a, b) => b.date.compareTo(a.date));
          
          return ListView.builder(
            itemCount: sortedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = sortedTransactions[index];
              final isPositive = transaction.transactionType == 'Sold';
              
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
                            transaction.symbol,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            transaction.transactionType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildDetailsRow('Date', DateFormat('dd-MM-yyyy').format(transaction.date)),
                      _buildDetailsRow('Quantity', '${transaction.quantity} shares'),
                      _buildDetailsRow('Price', '₹${transaction.price.toStringAsFixed(2)}'),
                      _buildDetailsRow(
                        'Total Value', 
                        '₹${(transaction.quantity * transaction.price).toStringAsFixed(2)}',
                        textColor: isPositive ? Colors.green : Colors.red,
                      ),
                      _buildDetailsRow('Broker Number', transaction.brokerNumber),
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
