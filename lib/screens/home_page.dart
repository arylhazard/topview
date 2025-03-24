import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/screens/holdings_page.dart';
import 'package:topview/screens/input_page.dart';
import 'package:topview/screens/transactions_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    // Initialize the portfolio data after checking permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndInitialize();
    });
  }
  
  // Check permissions and then initialize
  Future<void> _checkPermissionsAndInitialize() async {
    try {
      final status = await Permission.sms.status;
      
      if (status.isDenied || status.isPermanentlyDenied) {
        setState(() {
          _permissionDenied = true;
        });
      } else {
        await Provider.of<PortfolioProvider>(context, listen: false).initialize();
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      // Fall back to manual input if permissions fail
      setState(() {
        _permissionDenied = true;
      });
    }
  }
  
  // Request permissions
  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.sms.request();
      
      if (status.isGranted) {
        setState(() {
          _permissionDenied = false;
        });
        await Provider.of<PortfolioProvider>(context, listen: false).initialize();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TopView Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!_permissionDenied) {
                Provider.of<PortfolioProvider>(context, listen: false).fetchSmsMessages();
              } else {
                _requestPermissions();
              }
            },
          ),
        ],
      ),
      body: _permissionDenied 
          ? _buildPermissionDeniedView() 
          : Consumer<PortfolioProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading SMS messages...'),
                      ],
                    ),
                  );
                }
                
                if (provider.availableClientIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No broker messages found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.fetchSmsMessages();
                          },
                          child: const Text('Scan Messages'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InputPage(),
                              ),
                            );
                          },
                          child: const Text('Enter Message Manually'),
                        ),
                      ],
                    ),
                  );
                }
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client ID Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Client ID',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: provider.currentClientId.isEmpty ? null : provider.currentClientId,
                                decoration: const InputDecoration(
                                  hintText: 'Select Client ID',
                                  border: OutlineInputBorder(),
                                ),
                                items: provider.availableClientIds.map((clientId) {
                                  return DropdownMenuItem<String>(
                                    value: clientId,
                                    child: Text(clientId),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setClientId(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Portfolio Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Portfolio Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryItem('Holdings Count', '${provider.holdings.length}'),
                              _buildSummaryItem('Total Invested', '₹${_calculateTotalInvestment(provider)}'),
                              _buildSummaryItem('Current Value', '₹${_calculateTotalCurrentValue(provider)}'),
                              _buildSummaryItem('Unrealized P/L', '₹${(_calculateTotalCurrentValue(provider) - _calculateTotalInvestment(provider)).toStringAsFixed(2)}'),
                              _buildSummaryItem('Realized P/L', '₹${provider.realizedProfitLoss.toStringAsFixed(2)}'),
                              _buildSummaryItem('Break-even Value', '₹${provider.breakEvenValue.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Holdings Preview - Renamed and restructured
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Holdings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              provider.holdings.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No holdings found'),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: provider.holdings.length > 3
                                          ? 3
                                          : provider.holdings.length,
                                      itemBuilder: (context, index) {
                                        final holding = provider.holdings[index];
                                        return ListTile(
                                          title: Text(holding.symbol),
                                          subtitle: Text('${holding.quantity} shares @ ₹${holding.averageBuyPrice.toStringAsFixed(2)}'),
                                          trailing: Text('₹${holding.currentValue.toStringAsFixed(2)}'),
                                        );
                                      },
                                    ),
                              // Show All button now below the list
                              const SizedBox(height: 8),
                              if (provider.holdings.isNotEmpty && provider.holdings.length > 3)
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const HoldingsPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('Show All Holdings'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recent Transactions Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              provider.transactions.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('No transactions found'),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: provider.transactions.length > 3
                                          ? 3
                                          : provider.transactions.length,
                                      itemBuilder: (context, index) {
                                        final reversedIndex = provider.transactions.length - 1 - index;
                                        final transaction = provider.transactions[reversedIndex];
                                        return ListTile(
                                          title: Text('${transaction.symbol} - ${transaction.transactionType}'),
                                          subtitle: Text(
                                            '${DateFormat('dd-MM-yyyy').format(transaction.date)} | ${transaction.quantity} @ ₹${transaction.price}'
                                          ),
                                          trailing: Text(
                                            '₹${(transaction.quantity * transaction.price).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: transaction.transactionType == 'Purchased'
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              // Show All Transactions button
                              const SizedBox(height: 8),
                              if (provider.transactions.isNotEmpty && provider.transactions.length > 3)
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const TransactionsPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('Show All Transactions'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InputPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.message_rounded,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'SMS Permission Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'TopView needs access to your SMS messages to automatically read broker transaction messages.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestPermissions,
            child: const Text('Grant Permission'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InputPage(),
                ),
              );
            },
            child: const Text('Enter Message Manually'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  double _calculateTotalInvestment(PortfolioProvider provider) {
    double total = 0;
    for (var holding in provider.holdings) {
      total += holding.investedValue;
    }
    return total;
  }
  
  double _calculateTotalCurrentValue(PortfolioProvider provider) {
    double total = 0;
    for (var holding in provider.holdings) {
      total += holding.currentValue;
    }
    return total;
  }
}
