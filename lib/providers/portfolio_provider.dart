import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/models/client.dart';
import 'package:topview/services/portfolio_service.dart';
import 'package:topview/services/sms_service.dart';
import 'package:topview/services/client_dao.dart';
import 'package:topview/utils/message_parser.dart';
import '../services/transaction_dao_new.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Holding> _holdings = [];
  double _realizedProfitLoss = 0;
  double _breakEvenValue = 0;
  String _currentClientId = '';
  List<String> _availableClientIds = [];
  bool _isLoadingMessages = false;
  bool _hasPermissionError = false;
  Transaction? _lastTransaction;
  
  List<Transaction> get transactions => _transactions;
  List<Holding> get holdings => _holdings;
  double get realizedProfitLoss => _realizedProfitLoss;
  double get breakEvenValue => _breakEvenValue;
  String get currentClientId => _currentClientId;
  List<String> get availableClientIds => _availableClientIds;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasPermissionError => _hasPermissionError;
  Transaction? get lastTransaction => _lastTransaction;
  // Initialize portfolio data
  Future<void> initialize() async {
    try {
      // First load existing data from database
      await _loadClientsFromDatabase();
      
      // If we have existing clients, load their data immediately
      if (_availableClientIds.isNotEmpty) {
        setClientId(_availableClientIds.first);
      }
      
      // Then update from SMS in background (only fetch new messages)
      await _fetchSmsMessagesIncrementally();
    } catch (e) {
      debugPrint('Error initializing portfolio: $e');
    }
  }

  // Load clients from database
  Future<void> _loadClientsFromDatabase() async {
    try {
      final clients = await ClientDAO.getAllClients();
      _availableClientIds = clients.map((c) => c.id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading clients from database: $e');
    }
  }
  
  // Fetch SMS messages and extract client IDs
  Future<void> fetchSmsMessages() async {
    _isLoadingMessages = true;
    _hasPermissionError = false;
    notifyListeners();
    
    try {
      // Request permission and get messages
      final hasPermission = await SmsService.requestSmsPermission();
      
      if (hasPermission) {
        final messages = await SmsService.getBrokerMessages();
        await processAllMessages(messages);
      } else {
        _hasPermissionError = true;
      }
    } catch (e) {
      debugPrint('Error fetching SMS messages: $e');
      _hasPermissionError = true;
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }
    // Process all broker messages
  Future<void> processAllMessages(List<SmsMessage> messages) async {
    Set<String> clientIdSet = {};
    
    for (var message in messages) {
      final clientId = MessageParser.extractClientId(message.body ?? '');
      if (clientId != null) {
        clientIdSet.add(clientId);
        await processMessage(message.body ?? '', useExtractedClientId: true);
      }
    }
    
    _availableClientIds = clientIdSet.toList()..sort();
    notifyListeners();
  }
    // Set active client ID
  void setClientId(String clientId) {
    _currentClientId = clientId;
    loadTransactions();
  }

  // Load transactions for current client ID
  Future<void> loadTransactions() async {
    if (_currentClientId.isEmpty) return;    try {
      _transactions = await TransactionDAO.getTransactionsByClientId(_currentClientId);
      _lastTransaction = await TransactionDAO.getLatestTransaction(_currentClientId);
      _calculatePortfolioMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
    // Process new broker message
  Future<bool> processMessage(String message, {bool useExtractedClientId = false}) async {
    final clientId = useExtractedClientId ? MessageParser.extractClientId(message) : _currentClientId;
    
    if (clientId == null && useExtractedClientId) {
      return false;
    }
    
    final newTransactions = MessageParser.parseMessage(
      message, 
      clientId: useExtractedClientId ? null : _currentClientId
    );
    
    if (newTransactions.isNotEmpty) {
      await TransactionDAO.insertTransactions(newTransactions);
      
      // Add new client ID to the list if needed
      if (useExtractedClientId && clientId != null && !_availableClientIds.contains(clientId)) {
        _availableClientIds.add(clientId);
        _availableClientIds.sort();
        
        // Create client record
        final client = Client(
          id: clientId,
          createdAt: DateTime.now(),
          lastTransactionDate: newTransactions.first.date,
        );
        await ClientDAO.insertOrUpdateClient(client);
        
        notifyListeners();
      }
      
      // Update client's last transaction date
      if (clientId != null) {
        await ClientDAO.updateLastTransactionDate(clientId, newTransactions.first.date);
      }
      
      // Only reload if the current client ID matches
      if (newTransactions.first.clientId == _currentClientId) {
        await loadTransactions();
      }
      
      return true;
    }
    
    return false;
  }
  
  // Calculate all portfolio metrics
  void _calculatePortfolioMetrics() {
    _holdings = PortfolioService.calculateHoldings(_transactions);
    _realizedProfitLoss = PortfolioService.calculateRealizedProfitLoss(_transactions);
    _breakEvenValue = PortfolioService.calculateBreakEvenValue(_transactions, _holdings);
  }
    // Clear all data (for testing)
  Future<void> clearData() async {
    await TransactionDAO.deleteAllTransactions();
    await ClientDAO.deleteAllClients();
    _availableClientIds = [];
    _currentClientId = '';
    _transactions = [];
    _holdings = [];
    _lastTransaction = null;
    notifyListeners();
  }

  // Search transactions with various filters
  Future<List<Transaction>> searchTransactions({
    String? symbol,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return await TransactionDAO.searchTransactions(
      clientId: _currentClientId,
      symbol: symbol,
      transactionType: transactionType,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  // Get last transaction insight message
  String getLastTransactionInsight() {
    if (_lastTransaction == null) {
      return "No activity recorded yet.";
    }

    final daysDiff = DateTime.now().difference(_lastTransaction!.date).inDays;
    final transactionType = _lastTransaction!.transactionType == 'Purchased' ? 'Bought' : 'Sold';
    
    if (daysDiff == 0) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} today.";
    } else if (daysDiff == 1) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} yesterday.";
    } else if (daysDiff <= 7) {
      return "Last activity: $transactionType ${_lastTransaction!.quantity} shares of ${_lastTransaction!.symbol} $daysDiff days ago.";
    } else {
      return "No activity recorded in the last $daysDiff days.";
    }
  }
    // Fetch SMS messages incrementally (only new messages)
  Future<void> _fetchSmsMessagesIncrementally() async {
    try {
      // Get the latest transaction date to filter new messages
      DateTime? lastTransactionDate;
      if (_availableClientIds.isNotEmpty) {
        final allTransactions = <Transaction>[];
        for (String clientId in _availableClientIds) {
          final clientTransactions = await TransactionDAO.getTransactionsByClientId(clientId);
          allTransactions.addAll(clientTransactions);
        }
        
        if (allTransactions.isNotEmpty) {
          allTransactions.sort((a, b) => b.date.compareTo(a.date));
          lastTransactionDate = allTransactions.first.date;
        }
      }
      
      // Fetch messages (in background without loading indicator)
      final hasPermission = await SmsService.requestSmsPermission();
      
      if (hasPermission) {
        final messages = await SmsService.getBrokerMessages();
        
        // Filter messages newer than last transaction date
        final newMessages = lastTransactionDate != null
            ? messages.where((msg) {
                // Basic date parsing from message - this might need refinement
                // For now, process all messages but we could optimize this
                return true;
              }).toList()
            : messages;
        
        await processAllMessages(newMessages);
      }
    } catch (e) {
      debugPrint('Error fetching SMS messages incrementally: $e');
    }
  }
}
