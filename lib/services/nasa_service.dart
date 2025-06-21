import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NasaApod {
  final String date;
  final String title;
  final String explanation;
  final String url;
  final String? hdurl;
  final String mediaType;

  NasaApod({
    required this.date,
    required this.title,
    required this.explanation,
    required this.url,
    this.hdurl,
    required this.mediaType,
  });

  factory NasaApod.fromJson(Map<String, dynamic> json) {
    return NasaApod(
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      url: json['url'] ?? '',
      hdurl: json['hdurl'],
      mediaType: json['media_type'] ?? 'image',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'explanation': explanation,
      'url': url,
      'hdurl': hdurl,
      'media_type': mediaType,
    };
  }
}

class NasaService {
  static const String _baseUrl = 'https://api.nasa.gov/planetary/apod';
  // Updated API key
  static const String _apiKey = 'Goz6G6zcNC26MigseVTboNpbfnxyrZU15ekly4QU';
  static const String _cachePrefix = 'nasa_apod_';
  static final Map<String, List<NasaApod>> _memoryCache = {};

  static Future<List<NasaApod>> getRecentApods({int count = 3}) async {
    try {
      final cacheKey = 'recent_$count';
      
      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        final cached = _memoryCache[cacheKey];
        if (cached != null && cached.isNotEmpty) {
          print('NASA Service: Returning from memory cache');
          return cached;
        }
      }

      // Check SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_cachePrefix$cacheKey');
      
      if (cachedData != null) {
        try {
          final decoded = json.decode(cachedData);
          final cacheTime = decoded['cache_time'] as int?;
          final now = DateTime.now().millisecondsSinceEpoch;
          
          // Cache valid for 6 hours
          if (cacheTime != null && (now - cacheTime) < 6 * 60 * 60 * 1000) {
            final apods = (decoded['data'] as List)
                .map((item) => NasaApod.fromJson(Map<String, dynamic>.from(item)))
                .toList();
            _memoryCache[cacheKey] = apods;
            print('NASA Service: Returning from persistent cache');
            return apods;
          }
        } catch (e) {
          print('NASA Service: Cache decode error: $e');
          // Invalid cache, continue to fetch
        }
      }

      print('NASA Service: Fetching from API');
      // Fetch from API with timeout
      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&count=$count'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('NASA Service: API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('NASA Service: Response received, parsing...');
        
        final dynamic data = json.decode(responseBody);
        List<NasaApod> apods;
        
        if (data is List) {
          apods = data.map((item) => NasaApod.fromJson(Map<String, dynamic>.from(item))).toList();
        } else if (data is Map) {
          // Single APOD response
          apods = [NasaApod.fromJson(Map<String, dynamic>.from(data))];
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Filter to only include images (no videos)
        final imageApods = apods.where((apod) => 
          apod.mediaType == 'image' && 
          apod.url.isNotEmpty &&
          (apod.url.toLowerCase().contains('.jpg') || 
           apod.url.toLowerCase().contains('.jpeg') || 
           apod.url.toLowerCase().contains('.png'))
        ).toList();
        
        print('NASA Service: Found ${imageApods.length} image APODs');
        
        // If we don't have enough images, try to get today's APOD
        if (imageApods.length < count) {
          final todayApod = await _getTodayApod();
          if (todayApod != null && !imageApods.any((apod) => apod.date == todayApod.date)) {
            imageApods.insert(0, todayApod);
          }
        }
        
        // If still not enough, use fallback images
        if (imageApods.length < count) {
          final fallbackApods = _getFallbackApods();
          imageApods.addAll(fallbackApods.take(count - imageApods.length));
        }
        
        final result = imageApods.take(count).toList();
        
        if (result.isNotEmpty) {
          // Cache the result
          await _cacheApods(cacheKey, result);
          _memoryCache[cacheKey] = result;
          print('NASA Service: Successfully cached ${result.length} APODs');
        }
        
        return result;
      } else if (response.statusCode == 403) {
        print('NASA Service: API key issue (403), using fallback');
        return _getFallbackApods().take(count).toList();
      } else {
        print('NASA Service: API error ${response.statusCode}: ${response.body}');
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      print('NASA Service: Error occurred: $e');
      
      // Return cached data if available
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'recent_$count';
        final cachedData = prefs.getString('$_cachePrefix$cacheKey');
        
        if (cachedData != null) {
          final decoded = json.decode(cachedData);
          final apods = (decoded['data'] as List)
              .map((item) => NasaApod.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          print('NASA Service: Returning stale cache data');
          return apods;
        }
      } catch (cacheError) {
        print('NASA Service: Cache retrieval failed: $cacheError');
      }
      
      // Last resort: return fallback images
      print('NASA Service: Using fallback images');
      return _getFallbackApods().take(count).toList();
    }
  }

  static Future<NasaApod?> _getTodayApod() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&date=$today'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apod = NasaApod.fromJson(Map<String, dynamic>.from(data));
        if (apod.mediaType == 'image') {
          return apod;
        }
      }
    } catch (e) {
      print('NASA Service: Failed to get today\'s APOD: $e');
    }
    return null;
  }

  static List<NasaApod> _getFallbackApods() {
    return [
      NasaApod(
        date: '2024-01-15',
        title: 'Hubble\'s View of Galaxy NGC 1365',
        explanation: 'This stunning image from the Hubble Space Telescope shows the barred spiral galaxy NGC 1365, located about 56 million light-years away in the constellation Fornax.',
        url: 'https://science.nasa.gov/wp-content/uploads/2023/09/hubble-ngc1365-potw2151a.jpg',
        hdurl: 'https://science.nasa.gov/wp-content/uploads/2023/09/hubble-ngc1365-potw2151a.jpg',
        mediaType: 'image',
      ),
      NasaApod(
        date: '2024-01-14',
        title: 'Earth\'s Airglow from Space',
        explanation: 'This image shows Earth\'s airglow as seen from the International Space Station, creating a beautiful green band around our planet\'s horizon.',
        url: 'https://science.nasa.gov/wp-content/uploads/2023/09/iss040e063094.jpg',
        hdurl: 'https://science.nasa.gov/wp-content/uploads/2023/09/iss040e063094.jpg',
        mediaType: 'image',
      ),
      NasaApod(
        date: '2024-01-13',
        title: 'Pillars of Creation',
        explanation: 'The iconic Pillars of Creation in the Eagle Nebula, captured by the James Webb Space Telescope in stunning detail.',
        url: 'https://science.nasa.gov/wp-content/uploads/2023/09/main_image_star_forming_region_carina_nircam_final-5mb.jpg',
        hdurl: 'https://science.nasa.gov/wp-content/uploads/2023/09/main_image_star_forming_region_carina_nircam_final-5mb.jpg',
        mediaType: 'image',
      ),
    ];
  }

  static Future<List<NasaApod>> _fetchMoreImages(int needed) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?api_key=$_apiKey&count=${needed * 2}'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final apods = data.map((item) => NasaApod.fromJson(Map<String, dynamic>.from(item))).toList();
        return apods.where((apod) => apod.mediaType == 'image').take(needed).toList();
      }
    } catch (e) {
      print('NASA Service: Failed to fetch more images: $e');
    }
    return [];
  }

  static Future<void> _cacheApods(String key, List<NasaApod> apods) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'cache_time': DateTime.now().millisecondsSinceEpoch,
        'data': apods.map((apod) => apod.toJson()).toList(),
      };
      await prefs.setString('$_cachePrefix$key', json.encode(cacheData));
      print('NASA Service: Successfully cached data');
    } catch (e) {
      print('NASA Service: Failed to cache NASA APOD data: $e');
    }
  }
}
