import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topview/providers/portfolio_provider.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = '';
  bool _hasError = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _processMessage() async {
    if (_messageController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a message';
        _hasError = true;
      });
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _statusMessage = '';
      _hasError = false;
    });
    
    try {
      final success = await Provider.of<PortfolioProvider>(context, listen: false)
          .processMessage(_messageController.text, useExtractedClientId: true);
      
      setState(() {
        _isProcessing = false;
        if (success) {
          _statusMessage = 'Message processed successfully!';
          _messageController.clear();
        } else {
          _statusMessage = 'No valid transaction data found in message';
          _hasError = true;
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error processing message: $e';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste Broker Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Since SMS permissions are not available, you can manually paste broker messages here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Example: BNo.55 Purchased on 2024-11-19 20240838091 (HLBSL 20 kitta @ 1060,NLICL 10 kitta @ 624) - BAmt.27,592.90',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('Process Message'),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasError ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _hasError ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Paste the broker message from STOCK_Alert\n'
              '2. The app will automatically extract the client ID and transaction details\n'
              '3. Transactions will be stored and portfolio updated',
            ),
          ],
        ),
      ),
    );
  }
}
