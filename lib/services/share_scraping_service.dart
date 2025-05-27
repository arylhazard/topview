import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import '../models/share_data.dart';
import 'database_service.dart';

class ShareScrapingService {
  static const String _baseUrl = 'https://www.sharesansar.com/today-share-price';

  String? _extractSiteDate(dom.Document document) {
    final dateRegExp = RegExp(r'As of\\s*:\\s*(\\d{4}-\\d{2}-\\d{2})', caseSensitive: false);
    
    // Attempt 1: Specific selector
    final specificElement = document.querySelector('div.dataasof h5');
    if (specificElement != null) {
      final text = specificElement.text.replaceAll('\\n', ' ').replaceAll(RegExp(r'[\\s\\u00A0]+'), ' ').trim();
      final match = dateRegExp.firstMatch(text);
      if (match?.group(1) != null) {
        try {
          final dateString = match!.group(1)!; // Safe due to check
          DateFormat('yyyy-MM-dd').parse(dateString);
          return dateString;
        } catch (e) {
          print('ShareScrapingService: Date format validation failed (specific): ${match?.group(1)}. Error: $e'); // Use ?. for safety in print
        }
      }
    }

    // Attempt 2: Fallback to broader search
    final possibleDateElements = document.querySelectorAll('div, span, p, h1, h2, h3, h4, h5, h6, b, strong, td, th');
    for (var element in possibleDateElements) {
      final text = element.text.replaceAll('\\n', ' ').replaceAll(RegExp(r'[\\s\\u00A0]+'), ' ').trim();
      if (!text.toLowerCase().contains('as of')) continue;
      final match = dateRegExp.firstMatch(text);
      if (match?.group(1) != null) {
        try {
          final dateString = match!.group(1)!; // Safe due to check
          DateFormat('yyyy-MM-dd').parse(dateString);
          return dateString;
        } catch (e) {
          print('ShareScrapingService: Date format validation failed (fallback): ${match?.group(1)}. Error: $e'); // Use ?. for safety in print
        }
      }
    }
    print('ShareScrapingService: Could not find site data date.');
    return null;
  }

  Future<Map<String, dynamic>> fetchAndProcessData({bool forceScrape = false}) async {
    String? latestStoredDate = await DatabaseService.getLatestStoredDataDate();
    String? siteDateString;
    List<ShareData> shareList = [];
    String dataSource = 'DB';
    String? errorMessage;

    // Helper to append error messages
    void appendError(String newErrorPart) {
      if (errorMessage == null) {
        errorMessage = newErrorPart;
      } else {
        errorMessage = '$errorMessage; $newErrorPart';
      }
    }

    // 1. Fetch HTML Content & Extract Site Date
    http.Response response;
    try {
      response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) {
        appendError('Failed to load page: ${response.statusCode}');
        if (latestStoredDate != null) {
          shareList.addAll(await DatabaseService.getShareDataByDate(latestStoredDate));
          return {'data': shareList, 'date': latestStoredDate, 'source': 'DB (Network Failed)', 'error': errorMessage};
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      appendError('Network error fetching page: ${e.toString()}');
      if (latestStoredDate != null) {
          shareList.addAll(await DatabaseService.getShareDataByDate(latestStoredDate));
          return {'data': shareList, 'date': latestStoredDate, 'source': 'DB (Network Error)', 'error': errorMessage};
      }
      return {'data': [], 'date': null, 'source': 'Error', 'error': errorMessage};
    }
    
    dom.Document document = parser.parse(response.body);
    siteDateString = _extractSiteDate(document);

    if (siteDateString == null) {
      appendError('Could not determine site data date from HTML.');
      if (latestStoredDate != null) {
        shareList.addAll(await DatabaseService.getShareDataByDate(latestStoredDate));
        return {'data': shareList, 'date': latestStoredDate, 'source': 'DB (Site Date Unknown)', 'error': errorMessage};
      }
      return {'data': [], 'date': null, 'source': 'Error', 'error': errorMessage};
    }

    // 2. Decide if scraping is necessary
    bool shouldScrape = forceScrape;
    if (!forceScrape) {
      if (latestStoredDate != null) {
        try {
          final siteDate = DateFormat('yyyy-MM-dd').parse(siteDateString);
          final dbDate = DateFormat('yyyy-MM-dd').parse(latestStoredDate);
          shouldScrape = siteDate.isAfter(dbDate);
        } catch (e) {
          print('ShareScrapingService: Error comparing dates: $e. Defaulting to scrape.');
          shouldScrape = true;
          appendError('Date comparison error: $e');
        }
      } else {
        shouldScrape = true; // No data in DB, so scrape
      }
    }

    // 3. Scrape or Load from DB
    if (shouldScrape) {
      dataSource = forceScrape ? 'Scraped (Forced)' : (latestStoredDate == null ? 'Scraped (Initial)' : 'Scraped (Newer)');
      List<ShareData> newlyScrapedList = _parseTableData(document);

      if (newlyScrapedList.isNotEmpty) {
        await DatabaseService.bulkInsertOrUpdateShareData(newlyScrapedList, siteDateString);
        shareList.addAll(newlyScrapedList);
      } else {
        appendError('No data scraped from table (empty or malformed).');
        shareList.addAll(await DatabaseService.getShareDataByDate(siteDateString));
        dataSource = shareList.isNotEmpty ? 'DB (Scrape Empty for $siteDateString)' : 'DB (Scrape Empty, No Prior for $siteDateString)';
        if (shareList.isEmpty) {
            appendError('And no data in DB for $siteDateString.');
        }
      }
    } else {
      if (latestStoredDate == null) { 
          appendError("Logic error: Tried to load from DB but latestStoredDate is null and not scraping.");
          return {'data': [], 'date': siteDateString, 'source': 'Error', 'error': errorMessage};
      }
      shareList.addAll(await DatabaseService.getShareDataByDate(latestStoredDate));
      siteDateString = latestStoredDate; 
      dataSource = 'DB (Up-to-date)';
    }

    return {
      'data': shareList,
      'date': siteDateString, // This will be the date of the data, whether scraped or from DB
      'source': dataSource,
      'error': errorMessage
    };
  }

  List<ShareData> _parseTableData(dom.Document document) {
    List<ShareData> scrapedList = [];
    dom.Element? table = document.querySelector('table#headFixed');
    if (table == null) {
      final tables = document.querySelectorAll('table');
      for (var t in tables) {
        final rows = t.querySelectorAll('tr');
        if (rows.length > 10) {
          final headerTexts = rows.first.querySelectorAll('th, td').map((c) => c.text.trim().toLowerCase()).toList();
          if (headerTexts.contains('symbol') && headerTexts.contains('ltp') && (headerTexts.contains('diff %') || headerTexts.contains('%change'))) {
            table = t;
            break;
          }
        }
      }
    }

    if (table == null) {
      print('ShareScrapingService: Target table not found for parsing.');
      return scrapedList; // Return empty list if no table
    }

    final rows = table.querySelectorAll('tr');
    bool firstRowSkipped = false;
    for (var row in rows) {
      if (!firstRowSkipped) {
        if (row.querySelectorAll('th').isNotEmpty || row.text.toLowerCase().contains('symbol')) {
          firstRowSkipped = true;
          continue;
        }
      }
      final cells = row.querySelectorAll('td');
      if (cells.length > ShareData.percentChangeIndex) {
        try {
          final share = ShareData.fromRow(cells.map((c) => c.text.trim()).toList());
          if (share.symbol != 'ErrorInSymbol' && share.ltp != 'N/A') {
            scrapedList.add(share);
          }
        } catch (e) {
          print('ShareScrapingService: Error parsing row: $e');
        }
      }
    }
    return scrapedList;
  }
}
