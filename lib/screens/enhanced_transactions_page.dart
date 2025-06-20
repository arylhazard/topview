import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:topview/providers/portfolio_provider.dart';
import 'package:topview/models/transaction.dart';
import 'package:intl/intl.dart';

class EnhancedTransactionsPage extends StatefulWidget {
  const EnhancedTransactionsPage({super.key});

  @override
  State<EnhancedTransactionsPage> createState() => _EnhancedTransactionsPageState();
}

class _EnhancedTransactionsPageState extends State<EnhancedTransactionsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
    String _searchQuery = '';
  String? _selectedTransactionType;
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  int _currentOffset = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool _groupByTicker = false; // New grouping toggle

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scrollController.addListener(_onScroll);
    _loadInitialTransactions();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadInitialTransactions() {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    setState(() {
      _filteredTransactions = _groupTransactionsByDate(provider.transactions);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    try {
      final moreTransactions = await provider.searchTransactions(
        symbol: _searchQuery.isEmpty ? null : _searchQuery,
        transactionType: _selectedTransactionType,
        limit: _pageSize,
        offset: _currentOffset + _pageSize,
      );

      setState(() {
        _currentOffset += _pageSize;
        if (moreTransactions.length < _pageSize) {
          _hasMoreData = false;
        }
        _filteredTransactions.addAll(moreTransactions);
      });
    } catch (e) {
      debugPrint('Error loading more transactions: $e');
    }

    setState(() => _isLoading = false);
  }

  List<Transaction> _groupTransactionsByDate(List<Transaction> transactions) {
    // For now, return sorted transactions - grouping will be visual
    final sorted = List<Transaction>.from(transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  void _filterTransactions() async {
    setState(() => _isLoading = true);

    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    
    try {
      final filtered = await provider.searchTransactions(
        symbol: _searchQuery.isEmpty ? null : _searchQuery,
        transactionType: _selectedTransactionType,
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _filteredTransactions = filtered;
        _currentOffset = 0;
        _hasMoreData = filtered.length == _pageSize;
      });
    } catch (e) {
      debugPrint('Error filtering transactions: $e');
      _loadInitialTransactions();
    }

    setState(() => _isLoading = false);
  }

  String _getDateGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    
    final currentDate = _filteredTransactions[index].date;
    final previousDate = _filteredTransactions[index - 1].date;
    
    return !_isSameDay(currentDate, previousDate);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadInitialTransactions();
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedTransactionType = null;
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [                  BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Ticker',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _filterTransactions();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterTransactions();
                    },
                  ),
                  const SizedBox(height: 8), // Reduced spacing
                  // Filter Chips Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Filter:', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: const Text('Bought', style: TextStyle(fontSize: 12)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              selected: _selectedTransactionType == 'Purchased',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? 'Purchased' : null;
                                });
                                _filterTransactions();
                              },
                            ),
                            FilterChip(
                              label: const Text('Sold', style: TextStyle(fontSize: 12)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              selected: _selectedTransactionType == 'Sold',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? 'Sold' : null;
                                });
                                _filterTransactions();
                              },
                            ),
                            FilterChip(
                              label: const Text('Group by Ticker', style: TextStyle(fontSize: 12)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              selected: _groupByTicker,
                              onSelected: (selected) {
                                setState(() {
                                  _groupByTicker = selected;
                                });
                                _filterTransactions();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Transactions List
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )                  : _groupByTicker 
                    ? _buildGroupedTransactionsList(theme, isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredTransactions.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredTransactions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final transaction = _filteredTransactions[index];
                          final showDateHeader = !_groupByTicker && _shouldShowDateHeader(index);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    _getDateGroupHeader(transaction.date),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              _buildTransactionCard(transaction, theme, isDark),
                            ],
                          );
                        },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, ThemeData theme, bool isDark) {
    final isPositive = transaction.transactionType == 'Sold';
    final totalValue = transaction.quantity * transaction.price;
    
    // Determine card accent color based on transaction value
    Color accentColor;
    if (totalValue > 100000) {
      accentColor = Colors.orange;
    } else if (totalValue > 50000) {
      accentColor = Colors.blue;
    } else {
      accentColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.symbol,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      if (totalValue > 50000) ...[
                        const SizedBox(width: 8),                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.transactionType,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Date',
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      Icons.calendar_today,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Quantity',
                      '${transaction.quantity} shares',
                      Icons.numbers,
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Price',
                      '₹${transaction.price.toStringAsFixed(2)}',
                      Icons.currency_rupee,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Total Value',
                      '₹${totalValue.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      theme,
                      valueColor: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (transaction.brokerNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailItem(
                  'Broker Number',
                  transaction.brokerNumber,
                  Icons.business,
                  theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      children: [        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionsList(ThemeData theme, bool isDark) {
    // Group transactions by symbol
    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (var transaction in _filteredTransactions) {
      if (groupedTransactions.containsKey(transaction.symbol)) {
        groupedTransactions[transaction.symbol]!.add(transaction);
      } else {
        groupedTransactions[transaction.symbol] = [transaction];
      }
    }
    
    // Sort symbols alphabetically
    final sortedSymbols = groupedTransactions.keys.toList()..sort();
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedSymbols.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedSymbols.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final symbol = sortedSymbols[index];
        final transactions = groupedTransactions[symbol]!;
        
        // Sort transactions within group by date (newest first)
        transactions.sort((a, b) => b.date.compareTo(a.date));
        
        // Calculate totals for this symbol
        double totalQuantity = 0;
        double totalValue = 0;
        int buyCount = 0;
        int sellCount = 0;
        
        for (var transaction in transactions) {
          if (transaction.transactionType == 'Purchased') {
            totalQuantity += transaction.quantity;
            buyCount++;
          } else {
            totalQuantity -= transaction.quantity;
            sellCount++;
          }
          totalValue += transaction.quantity * transaction.price;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(                          '${transactions.length} transactions • $buyCount buys • $sellCount sells',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalQuantity.toStringAsFixed(0)} shares',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(                      '₹${totalValue.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Transactions for this symbol
            ...transactions.map((transaction) => 
              _buildTransactionCard(transaction, theme, isDark)
            ).toList(),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
