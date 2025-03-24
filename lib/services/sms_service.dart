import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  static final SmsQuery _query = SmsQuery();
  
  // Request SMS permissions with error handling
  static Future<bool> requestSmsPermission() async {
    try {
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        final result = await Permission.sms.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      return false;
    }
  }
  
  // Get messages from a specific sender
  static Future<List<SmsMessage>> getMessagesFromSender(String sender) async {
    try {
      bool hasPermission = await requestSmsPermission();
      if (!hasPermission) {
        debugPrint('SMS permission not granted');
        return [];
      }
      
      List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        address: sender,
      );
      return messages;
    } catch (e) {
      debugPrint('Error getting SMS messages: $e');
      return [];
    }
  }
  
  // Find all broker messages containing transaction info
  static Future<List<SmsMessage>> getBrokerMessages() async {
    try {
      return await getMessagesFromSender('STOCK_Alert');
    } catch (e) {
      debugPrint('Error getting broker messages: $e');
      return [];
    }
  }
}
