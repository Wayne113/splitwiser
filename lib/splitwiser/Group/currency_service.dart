import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String apiUrl = 'https://api.exchangerate-api.com/v4/latest/';
  static const Duration cacheDuration = Duration(hours: 1);

  Future<double> getExchangeRate(String from, String to) async {
    try {
      final cachedRate = await _getCachedRate(from, to);
      if (cachedRate != null) {
        return cachedRate;
      }

      // Fetch from API
      final response = await http
          .get(
            Uri.parse('$apiUrl$from'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        if (rates.containsKey(to)) {
          final rate = (rates[to] as num).toDouble();

          // Cache the rate
          await _cacheRate(from, to, rate);

          return rate;
        } else {
          throw Exception('Currency $to not found in API response');
        }
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Try to get cached rate
      final fallbackRate = await _getCachedRate(from, to, ignoreExpiry: true);
      if (fallbackRate != null) {
        return fallbackRate;
      }

      // Return 1.0 as last resort (no conversion)
      return 1.0;
    }
  }

  /// Convert amount from one currency to another
  Future<double> convertAmount(double amount, String from, String to) async {
    if (from == to) return amount;

    final rate = await getExchangeRate(from, to);
    return amount * rate;
  }

  /// Get cached exchange rate
  Future<double?> _getCachedRate(
    String from,
    String to, {
    bool ignoreExpiry = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${from}_${to}_rate';
      final timeKey = '${from}_${to}_time';

      final rate = prefs.getDouble(key);
      final timestamp = prefs.getInt(timeKey);

      if (rate != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (ignoreExpiry || now.difference(cacheTime) < cacheDuration) {
          return rate;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache exchange rate
  Future<void> _cacheRate(String from, String to, double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${from}_${to}_rate';
      final timeKey = '${from}_${to}_time';

      await prefs.setDouble(key, rate);
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("Error caching the rate: $e");
    }
  }

  String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'MYR':
        return 'RM';
      case 'SGD':
        return 'S\$';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      case 'PHP':
        return '₱';
      case 'VND':
        return '₫';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'JPY':
        return '¥';
      case 'USD':
        return '\$';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'NZD':
        return 'NZ\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'HKD':
        return 'HK\$';
      case 'TWD':
        return 'NT\$';
      default:
        return currencyCode;
    }
  }

  /// Clear all cached rates
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.contains('_rate') || key.contains('_time'),
      );

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print("Error clearing the currency cache: $e");
    }
  }
}
