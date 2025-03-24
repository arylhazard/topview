import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:topview/models/holding.dart';
import 'package:topview/models/transaction.dart';
import 'package:topview/services/portfolio_service.dart';
import 'package:topview/services/sms_service.dart';
import 'package:topview/services/storage_service.dart';
import 'package:topview/utils/message_parser.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Holding> _holdings = [];
  double _realizedProfitLoss = 0;
  double _breakEvenValue = 0;
  String _currentClientId = '';
  List<String> _availableClientIds = [];
  bool _isLoadingMessages = false;
  bool _hasPermissionError = false;
  
  List<Transaction> get transactions => _transactions;
  List<Holding> get holdings => _holdings;
  double get realizedProfitLoss => _realizedProfitLoss;
  double get breakEvenValue => _breakEvenValue;
  String get currentClientId => _currentClientId;
  List<String> get availableClientIds => _availableClientIds;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasPermissionError => _hasPermissionError;
  
  // Initialize portfolio data
  Future<void> initialize() async {
    try {
      await fetchSmsMessages();
      if (_availableClientIds.isNotEmpty) {
        setClientId(_availableClientIds.first);
      }
    } catch (e) {
      debugPrint('Error initializing portfolio: $e');
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
    if (_currentClientId.isEmpty) return;
    
    _transactions = await StorageService.getTransactionsByClientId(_currentClientId);
    _calculatePortfolioMetrics();
    notifyListeners();
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
      await StorageService.saveTransactions(newTransactions);
      
      // Add new client ID to the list if needed
      if (useExtractedClientId && clientId != null && !_availableClientIds.contains(clientId)) {
        _availableClientIds.add(clientId);
        _availableClientIds.sort();
        notifyListeners();
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
    await StorageService.clearTransactions();
    _availableClientIds = [];
    _currentClientId = '';
    _transactions = [];
    _holdings = [];
    notifyListeners();
  }
}
