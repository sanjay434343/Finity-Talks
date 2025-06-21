import 'dart:convert';
import 'package:http/http.dart' as http;

class HoroscopeService {
  static const String _baseUrl = 'https://ohmanda.com/api/horoscope';
  
  static Future<HoroscopeData> getTodayHoroscope(String sign) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$sign/'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HoroscopeData(
          sign: sign,
          horoscope: data['horoscope'] ?? 'No horoscope available today.',
          date: DateTime.now(),
        );
      } else {
        throw Exception('Failed to load horoscope');
      }
    } catch (e) {
      throw Exception('Error fetching horoscope: $e');
    }
  }

  static List<String> get availableSigns => [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
  ];

  static String getSignDisplayName(String sign) {
    final Map<String, String> signNames = {
      'aries': 'Aries ♈',
      'taurus': 'Taurus ♉',
      'gemini': 'Gemini ♊',
      'cancer': 'Cancer ♋',
      'leo': 'Leo ♌',
      'virgo': 'Virgo ♍',
      'libra': 'Libra ♎',
      'scorpio': 'Scorpio ♏',
      'sagittarius': 'Sagittarius ♐',
      'capricorn': 'Capricorn ♑',
      'aquarius': 'Aquarius ♒',
      'pisces': 'Pisces ♓',
    };
    return signNames[sign] ?? sign.toUpperCase();
  }
}

class HoroscopeData {
  final String sign;
  final String horoscope;
  final DateTime date;

  HoroscopeData({
    required this.sign,
    required this.horoscope,
    required this.date,
  });

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
