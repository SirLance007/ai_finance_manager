import 'dart:convert';
import 'package:http/http.dart' as http;

class FinanceApiService {
  /// Search for tickers using Yahoo Finance Autocomplete API
  static Future<List<Map<String, dynamic>>> searchTickers(String query) async {
    if (query.trim().isEmpty) return [];
    
    final url = Uri.parse('https://query2.finance.yahoo.com/v1/finance/search?q=$query&quotesCount=6&newsCount=0');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quotes = data['quotes'] as List<dynamic>?;
        if (quotes != null) {
          return quotes.map((q) => {
            'symbol': q['symbol']?.toString() ?? '',
            'shortname': (q['shortname'] ?? q['longname'] ?? q['symbol'])?.toString() ?? '',
            'exchDisp': q['exchDisp']?.toString() ?? '',
          }).toList();
        }
      }
    } catch (e) {
      print('Search API Error: $e');
    }
    return [];
  }

  /// Fetches live market data from Yahoo Finance API for a given ticker symbol.
  /// Example: 'RELIANCE.NS' for current NSE data, or 'BTC-USD' for Crypto.
  static Future<Map<String, double>?> getLivePrice(String ticker) async {
    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=1d');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']['result'];
        
        if (result != null && result.isNotEmpty) {
          final meta = result[0]['meta'];
          double currentPrice = (meta['regularMarketPrice'] ?? 0.0).toDouble();
          double previousClose = (meta['previousClose'] ?? currentPrice).toDouble();
          
          return {
            'currentPrice': currentPrice,
            'previousClose': previousClose,
          };
        }
      }
      return null;
    } catch (e) {
      print('Finance API Error: $e');
      return null;
    }
  }

  /// Helper to quickly query if a stock exists via basic check
  static Future<bool> verifyTicker(String ticker) async {
    final res = await getLivePrice(ticker);
    return res != null && res['currentPrice']! > 0;
  }
}
