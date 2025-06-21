import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_model.dart';

class QuoteService {
  static const String _baseUrl = 'https://zenquotes.io/api';
  static const String _quotePrefix = 'daily_quote_';
  static const String _lastViewedKey = 'last_viewed_quote_date';

  static Future<QuoteModel?> getTodayQuote() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Try to get cached quote for today
    final cachedQuote = await _getCachedQuote(today);
    if (cachedQuote != null) {
      return cachedQuote;
    }

    // Fetch new quote from API
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final quote = QuoteModel.fromApi(data[0]);
          await _cacheQuote(quote);
          return quote;
        }
      }
    } catch (e) {
      print('Failed to fetch quote: $e');
    }

    return null;
  }

  static Future<QuoteModel?> _getCachedQuote(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quoteJson = prefs.getString('$_quotePrefix$date');
      
      if (quoteJson != null) {
        final data = json.decode(quoteJson);
        return QuoteModel.fromJson(data);
      }
    } catch (e) {
      print('Failed to get cached quote: $e');
    }
    return null;
  }

  static Future<void> _cacheQuote(QuoteModel quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quoteJson = json.encode(quote.toJson());
      await prefs.setString('$_quotePrefix${quote.date}', quoteJson);
    } catch (e) {
      print('Failed to cache quote: $e');
    }
  }

  static Future<bool> shouldShowQuoteToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewed = prefs.getString(_lastViewedKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Show quote if not viewed today
      return lastViewed != today;
    } catch (e) {
      return true; // Show quote on error
    }
  }

  static Future<void> markQuoteAsViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_lastViewedKey, today);
    } catch (e) {
      print('Failed to mark quote as viewed: $e');
    }
  }

  static Future<void> clearOldQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      for (final key in keys) {
        if (key.startsWith(_quotePrefix)) {
          final date = key.substring(_quotePrefix.length);
          final quoteDate = DateTime.tryParse('${date}T00:00:00.000Z');
          
          if (quoteDate != null && quoteDate.isBefore(cutoffDate)) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Failed to clear old quotes: $e');
    }
  }
}
