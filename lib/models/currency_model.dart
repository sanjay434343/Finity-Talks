class CurrencyModel {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime? lastUpdated;

  CurrencyModel({
    required this.baseCurrency,
    required this.rates,
    this.lastUpdated,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse the rates map safely
      final ratesData = json['rates'] as Map<String, dynamic>? ?? {};
      final Map<String, double> parsedRates = {};
      
      // Convert all rate values to double safely
      ratesData.forEach((key, value) {
        if (value != null) {
          parsedRates[key] = value is double ? value : (value as num).toDouble();
        }
      });

      return CurrencyModel(
        baseCurrency: json['base_code'] as String? ?? 'USD',
        rates: parsedRates,
        lastUpdated: json['time_last_update_unix'] != null 
            ? DateTime.fromMillisecondsSinceEpoch((json['time_last_update_unix'] as int) * 1000)
            : null,
      );
    } catch (e) {
      print('Error parsing currency model: $e');
      // Return a fallback model with just USD
      return CurrencyModel(
        baseCurrency: 'USD',
        rates: {'USD': 1.0},
        lastUpdated: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'base_code': baseCurrency,
      'rates': rates,
      'time_last_update_unix': lastUpdated?.millisecondsSinceEpoch,
    };
  }
}
