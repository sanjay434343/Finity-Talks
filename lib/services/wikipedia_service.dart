import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_database_service.dart';

class WikipediaService {
  static final WikipediaService _instance = WikipediaService._internal();
  factory WikipediaService() => _instance;
  WikipediaService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();

  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1';
  static const String _randomUrl = 'https://en.wikipedia.org/api/rest_v1/page/random/summary';
  
  // Cache for episodes to avoid repeated API calls
  static List<WikipediaEpisode> _cachedEpisodes = [];
  static DateTime? _lastFetchTime;
  
  // Get random Wikipedia articles for podcast episodes
  static Future<List<WikipediaEpisode>> getRandomEpisodes({int count = 3}) async {
    List<WikipediaEpisode> episodes = [];
    int attempts = 0;
    const maxAttempts = 50; // Try up to 50 times to get valid episodes
    
    try {
      // Keep trying until we have enough valid episodes
      while (episodes.length < count && attempts < maxAttempts) {
        final response = await http.get(
          Uri.parse(_randomUrl),
          headers: {
            'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final episode = WikipediaEpisode.fromJson(data);
          
          // Check if episode is valid and not a duplicate
          if (episode.isValid && !episodes.any((ep) => ep.title == episode.title)) {
            episodes.add(episode);
          }
        }
        
        attempts++;
        
        // Small delay to be respectful to the API
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // If we still don't have enough episodes, fill with fallback
      if (episodes.length < count) {
        final fallbackEpisodes = _getFallbackEpisodes();
        final usedTitles = episodes.map((ep) => ep.title).toSet();
        
        for (final fallback in fallbackEpisodes) {
          if (episodes.length >= count) break;
          if (!usedTitles.contains(fallback.title)) {
            episodes.add(fallback);
          }
        }
      }
      
      // Cache the episodes if we have a good amount
      if (episodes.length >= count) {
        _cachedEpisodes = episodes;
        _lastFetchTime = DateTime.now();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching Wikipedia episodes: $e');
      }
      
      // Return fallback episodes if API fails
      episodes = _getFallbackEpisodes();
    }
    
    // Ensure we always return at least the requested count
    if (episodes.length < count) {
      // Duplicate episodes if necessary to reach count
      final originalEpisodes = List<WikipediaEpisode>.from(episodes);
      while (episodes.length < count && originalEpisodes.isNotEmpty) {
        for (final episode in originalEpisodes) {
          if (episodes.length >= count) break;
          // Create a slightly modified duplicate
          episodes.add(WikipediaEpisode(
            title: '${episode.title} (Extended)',
            description: episode.description,
            category: episode.category,
            duration: episode.duration,
            imageUrl: episode.imageUrl,
            pageUrl: episode.pageUrl,
          ));
        }
      }
    }
    
    return episodes.take(count).toList();
  }
  
  // Get specific Wikipedia article by title
  static Future<WikipediaEpisode?> getEpisodeByTitle(String title) async {
    try {
      final encodedTitle = Uri.encodeComponent(title);
      final response = await http.get(
        Uri.parse('$_baseUrl/page/summary/$encodedTitle'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WikipediaEpisode.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching Wikipedia article: $e');
      }
    }
    
    return null;
  }
  
  // Get category-based episodes
  static Future<List<WikipediaEpisode>> getCategoryBasedEpisodes(List<String> categories, {int count = 3}) async {
    try {
      List<WikipediaEpisode> episodes = [];
      int attempts = 0;
      const maxAttempts = 50; // Increase attempts to find category-matching content
      
      // Keep trying until we have enough category-matching episodes
      while (episodes.length < count && attempts < maxAttempts) {
        final response = await http.get(
          Uri.parse(_randomUrl),
          headers: {
            'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final episode = WikipediaEpisode.fromJson(data);
          
          // Check if episode is valid and matches selected categories
          if (episode.isValid && !episodes.any((ep) => ep.title == episode.title)) {
            // Strict category matching
            final matchesCategory = categories.any((userCategory) {
              final categoryLower = userCategory.toLowerCase();
              final episodeCategoryLower = episode.category.toLowerCase();
              final titleLower = episode.title.toLowerCase();
              final descLower = episode.description.toLowerCase();
              
              // Direct category match or strong keyword presence
              return episodeCategoryLower == categoryLower ||
                     titleLower.contains(categoryLower) ||
                     descLower.contains(categoryLower) ||
                     _hasStrongCategoryMatch(titleLower, descLower, categoryLower);
            });
            
            if (matchesCategory) {
              episodes.add(episode);
              if (kDebugMode) {
                print('Found matching episode: ${episode.title} (${episode.category}) for categories: $categories');
              }
            }
          }
        }
        
        attempts++;
        
        // Small delay to be respectful to the API
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      // If we still don't have enough episodes, use targeted fallback based on categories
      if (episodes.length < count) {
        final fallbackEpisodes = _getTargetedFallbackEpisodes(categories);
        final usedTitles = episodes.map((ep) => ep.title).toSet();
        
        for (final fallback in fallbackEpisodes) {
          if (episodes.length >= count) break;
          if (!usedTitles.contains(fallback.title)) {
            episodes.add(fallback);
          }
        }
      }
      
      if (kDebugMode) {
        print('Final category-based episodes count: ${episodes.length}');
        for (final ep in episodes) {
          print('- ${ep.title} (${ep.category})');
        }
      }
      
      return episodes.take(count).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting category-based episodes: $e');
      }
      // Return targeted fallback episodes
      return _getTargetedFallbackEpisodes(categories).take(count).toList();
    }
  }

  // Check for strong category matches using specific keywords
  static bool _hasStrongCategoryMatch(String title, String description, String category) {
    final content = '$title $description';
    
    switch (category) {
      case 'science':
        return RegExp(r'\b(scientist|research|discovery|theory|experiment|scientific|laboratory|study|analysis|hypothesis)\b', caseSensitive: false).hasMatch(content);
      case 'technology':
        return RegExp(r'\b(computer|software|internet|digital|algorithm|programming|artificial|intelligence|tech|innovation)\b', caseSensitive: false).hasMatch(content);
      case 'history':
        return RegExp(r'\b(historical|ancient|century|empire|civilization|war|battle|dynasty|era|period|past)\b', caseSensitive: false).hasMatch(content);
      case 'health':
        return RegExp(r'\b(medical|medicine|doctor|hospital|disease|treatment|therapy|health|patient|clinical)\b', caseSensitive: false).hasMatch(content);
      default:
        return false;
    }
  }

  // Get targeted fallback episodes based on selected categories
  static List<WikipediaEpisode> _getTargetedFallbackEpisodes(List<String> categories) {
    final Map<String, List<WikipediaEpisode>> categoryEpisodes = {
      'Science': [
        WikipediaEpisode(
          title: 'Quantum Physics Breakthroughs',
          description: 'Exploring the latest discoveries in quantum mechanics and their implications for technology.',
          category: 'Science',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Quantum_physics',
        ),
        WikipediaEpisode(
          title: 'DNA Research Revolution',
          description: 'How genetic research is changing our understanding of life and medicine.',
          category: 'Science',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/DNA',
        ),
      ],
      'Technology': [
        WikipediaEpisode(
          title: 'Artificial Intelligence Revolution',
          description: 'How AI is transforming industries and changing the way we work and live.',
          category: 'Technology',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Artificial_intelligence',
        ),
        WikipediaEpisode(
          title: 'Blockchain Innovation',
          description: 'Understanding blockchain technology and its applications beyond cryptocurrency.',
          category: 'Technology',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Blockchain',
        ),
      ],
      'History': [
        WikipediaEpisode(
          title: 'Ancient Roman Empire',
          description: 'Exploring the rise and fall of one of history\'s greatest civilizations.',
          category: 'History',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Roman_Empire',
        ),
        WikipediaEpisode(
          title: 'World War II Stories',
          description: 'Untold stories and historical facts from the Second World War.',
          category: 'History',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/World_War_II',
        ),
      ],
      'Health': [
        WikipediaEpisode(
          title: 'Modern Medicine Advances',
          description: 'Latest breakthroughs in medical research and treatment methods.',
          category: 'Health',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Medicine',
        ),
        WikipediaEpisode(
          title: 'Mental Health Awareness',
          description: 'Understanding mental health and the importance of psychological well-being.',
          category: 'Health',
          duration: _getRandomDuration(),
          imageUrl: null,
          pageUrl: 'https://en.wikipedia.org/wiki/Mental_health',
        ),
      ],
    };
    
    List<WikipediaEpisode> targetedEpisodes = [];
    
    // Add episodes from selected categories
    for (final category in categories) {
      final categoryKey = category.substring(0, 1).toUpperCase() + category.substring(1).toLowerCase();
      if (categoryEpisodes.containsKey(categoryKey)) {
        targetedEpisodes.addAll(categoryEpisodes[categoryKey]!);
      }
    }
    
    // Shuffle to provide variety
    targetedEpisodes.shuffle();
    
    return targetedEpisodes;
  }

  // Clear cache to force refresh
  static void clearCache() {
    _cachedEpisodes.clear();
    _lastFetchTime = null;
  }
  
  // Fallback episodes in case API fails
  static List<WikipediaEpisode> _getFallbackEpisodes() {
    return [
      WikipediaEpisode(
        title: 'The Science of Dreams',
        description: 'Exploring the mysterious world of sleep and consciousness, from REM cycles to lucid dreaming.',
        category: 'Science',
        duration: _getRandomDuration(),
        imageUrl: null,
        pageUrl: 'https://en.wikipedia.org/wiki/Dream',
      ),
      WikipediaEpisode(
        title: 'Ocean Mysteries',
        description: 'Dive deep into the unexplored depths of our planet and discover the wonders of marine life.',
        category: 'Nature',
        duration: _getRandomDuration(),
        imageUrl: null,
        pageUrl: 'https://en.wikipedia.org/wiki/Ocean',
      ),
      WikipediaEpisode(
        title: 'Ancient Civilizations',
        description: 'Uncovering secrets from lost cultures and empires that shaped human history.',
        category: 'History',
        duration: _getRandomDuration(),
        imageUrl: null,
        pageUrl: 'https://en.wikipedia.org/wiki/Ancient_history',
      ),
    ];
  }
  
  static String _getRandomDuration() {
    final durations = ['5 min', '8 min', '10 min', '12 min', '15 min'];
    return durations[Random().nextInt(durations.length)];
  }

  Future<List<WikipediaEpisode>> getDailyEpisodes() async {
    try {
      // First, try to get cached episodes
      final cachedEpisodes = await _localDb.getCachedEpisodes();
      if (cachedEpisodes != null) {
        if (kDebugMode) {
          print('Using cached episodes (${cachedEpisodes.length} episodes)');
        }
        return cachedEpisodes;
      }

      if (kDebugMode) {
        print('No valid cache found, fetching fresh episodes');
      }

      // If no valid cache, fetch fresh episodes
      final freshEpisodes = await _fetchFreshEpisodes();
      
      // Cache the fresh episodes
      await _localDb.cacheEpisodes(freshEpisodes);
      
      return freshEpisodes;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getDailyEpisodes: $e');
      }
      
      // If all else fails, try to return any cached episodes (even if expired)
      try {
        final db = await _localDb.database;
        final List<Map<String, dynamic>> maps = await db.query('episodes');
        
        if (maps.isNotEmpty) {
          if (kDebugMode) {
            print('Returning expired cache as fallback');
          }
          return maps.map((map) => WikipediaEpisode(
            title: map['title'],
            description: map['description'],
            category: map['category'],
            duration: map['duration'],
            imageUrl: map['image_url'],
            pageUrl: map['page_url'] ?? 'https://en.wikipedia.org',
          )).toList();
        }
      } catch (cacheError) {
        if (kDebugMode) {
          print('Error accessing fallback cache: $cacheError');
        }
      }
      
      // Return empty list if everything fails
      return [];
    }
  }

  Future<List<WikipediaEpisode>> _fetchFreshEpisodes() async {
    const categories = [
      'Science',
      'Technology', 
      'History',
      'Philosophy',
      'Literature',
      'Art',
      'Music',
      'Geography',
      'Biology',
      'Physics'
    ];

    final List<WikipediaEpisode> episodes = [];
    
    for (final category in categories) {
      try {
        final episode = await _fetchRandomTopicFromCategory(category);
        if (episode != null) {
          episodes.add(episode);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching episode for category $category: $e');
        }
      }
    }

    return episodes;
  }

  // Add the missing method
  Future<WikipediaEpisode?> _fetchRandomTopicFromCategory(String category) async {
    try {
      // Get a random article
      final response = await http.get(
        Uri.parse(_randomUrl),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final episode = WikipediaEpisode.fromJson(data);
        
        if (episode.isValid) {
          // Override category with the requested one
          return WikipediaEpisode(
            title: episode.title,
            description: episode.description,
            category: category,
            duration: episode.duration,
            imageUrl: episode.imageUrl,
            pageUrl: episode.pageUrl,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching episode for category $category: $e');
      }
    }
    
    return null;
  }

  // Force refresh episodes (ignore cache)
  Future<List<WikipediaEpisode>> forceRefreshEpisodes() async {
    try {
      if (kDebugMode) {
        print('Force refreshing episodes');
      }
      
      // Clear existing cache
      await _localDb.clearExpiredCache();
      
      // Fetch fresh episodes
      final freshEpisodes = await _fetchFreshEpisodes();
      
      // Cache the fresh episodes
      await _localDb.cacheEpisodes(freshEpisodes);
      
      return freshEpisodes;
    } catch (e) {
      if (kDebugMode) {
        print('Error in forceRefreshEpisodes: $e');
      }
      rethrow;
    }
  }

  // Get cache status for debugging
  Future<Map<String, dynamic>> getCacheStatus() async {
    return await _localDb.getCacheInfo();
  }
}

class WikipediaEpisode {
  final String title;
  final String description;
  final String category;
  final String duration;
  final String? imageUrl;
  final String pageUrl;
  final DateTime fetchedAt;
  
  WikipediaEpisode({
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    this.imageUrl,
    required this.pageUrl,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();
  
  factory WikipediaEpisode.fromJson(Map<String, dynamic> json) {
    // Extract and clean description
    String description = json['extract'] ?? json['description'] ?? '';
    if (description.isEmpty) {
      description = 'Discover interesting facts and stories about ${json['title'] ?? 'this topic'}.';
    }
    
    // Limit description length
    if (description.length > 150) {
      description = description.substring(0, 147) + '...';
    }
    
    // Determine category based on content
    String category = _determineCategory(json['title'] ?? '', description);
    
    // Generate random duration
    String duration = WikipediaService._getRandomDuration();
    
    return WikipediaEpisode(
      title: json['title'] ?? 'Interesting Topic',
      description: description,
      category: category,
      duration: duration,
      imageUrl: json['thumbnail']?['source'],
      pageUrl: json['content_urls']?['desktop']?['page'] ?? 'https://en.wikipedia.org',
      fetchedAt: DateTime.now(),
    );
  }
  
  static String _determineCategory(String title, String description) {
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();
    final content = '$titleLower $descLower';
    
    // More specific and comprehensive category detection
    final categoryPatterns = {
      'Science': [
        RegExp(r'\b(science|scientist|research|discovery|theory|experiment|scientific|laboratory|study|analysis|hypothesis|biology|chemistry|physics|astronomy|geology|ecology)\b'),
        RegExp(r'\b(nobel|academic|university|institute|lab|formula|equation|molecule|atom|cell|gene|evolution|fossil)\b'),
      ],
      'Technology': [
        RegExp(r'\b(technology|computer|software|internet|digital|algorithm|programming|artificial|intelligence|tech|innovation|electronic|device|app|system|network)\b'),
        RegExp(r'\b(startup|silicon|valley|microsoft|apple|google|facebook|tesla|patent|semiconductor|processor|coding)\b'),
      ],
      'History': [
        RegExp(r'\b(history|historical|ancient|century|empire|civilization|war|battle|dynasty|era|period|past|medieval|renaissance|revolution)\b'),
        RegExp(r'\b(bc|ad|anno|domini|archaeological|historian|chronicle|heritage|legacy|tradition|ancestor|monument|artifact)\b'),
      ],
      'Health': [
        RegExp(r'\b(health|medical|medicine|doctor|hospital|disease|treatment|therapy|patient|clinical|surgery|pharmaceutical|vaccine|diagnosis)\b'),
        RegExp(r'\b(wellness|fitness|nutrition|diet|exercise|mental|psychological|psychiatrist|nurse|healthcare|epidemic|pandemic|virus|bacteria)\b'),
      ],
      'Nature': [
        RegExp(r'\b(nature|animal|plant|forest|wildlife|environment|earth|species|ecosystem|conservation|biodiversity|habitat)\b'),
        RegExp(r'\b(ocean|mountain|river|climate|weather|geography|geological|national|park|reserve|endangered|extinct)\b'),
      ],
      'Culture': [
        RegExp(r'\b(culture|art|music|literature|philosophy|religion|society|tradition|language|festival|ceremony|ritual)\b'),
        RegExp(r'\b(artist|musician|author|poet|writer|composer|painter|sculptor|gallery|museum|theater|opera)\b'),
      ],
    };
    
    // Check each category with its patterns
    for (final entry in categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (pattern.hasMatch(content)) {
          return entry.key;
        }
      }
    }
    
    return 'General';
  }
  
  bool get isValid => title.isNotEmpty && description.isNotEmpty;
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'duration': duration,
    'imageUrl': imageUrl,
    'pageUrl': pageUrl,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}
