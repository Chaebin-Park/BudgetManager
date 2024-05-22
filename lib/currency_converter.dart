import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConverter {
  static const String apiKey = '2d75c6c943124ca798238b4eb816be49'; // Replace with your actual API key
  static const String apiUrl = 'https://openexchangerates.org/api/latest.json';

  static Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    final response = await http.get(Uri.parse('$apiUrl?app_id=$apiKey'));

    if (response.statusCode == 200) {
      final rates = json.decode(response.body)['rates'];
      double fromRate = rates[fromCurrency].toDouble();
      double toRate = rates[toCurrency].toDouble();
      return toRate / fromRate;
    } else {
      print('Failed to load exchange rates: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load exchange rates');
    }
  }
}
