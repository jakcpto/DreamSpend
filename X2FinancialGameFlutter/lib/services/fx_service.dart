import 'dart:convert';

import 'package:http/http.dart' as http;

class LiveFxService {
  /// Fetches the exchange rate from [fromCurrency] to [toCurrency].
  /// Returns null on error.
  static Future<double?> fetchRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return 1.0;
    try {
      final uri = Uri.parse(
        'https://api.frankfurter.app/latest?from=$fromCurrency&to=$toCurrency',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = json['rates'] as Map<String, dynamic>?;
      if (rates == null) return null;
      return (rates[toCurrency] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }
}
