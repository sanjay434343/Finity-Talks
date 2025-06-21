import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_model.dart';

class MusicService {
  static const String _baseUrl = 'https://itunes.apple.com/search';
  static const Duration _cacheValidDuration = Duration(hours: 6);
  
  // Cache variables
  static Map<String, List<MusicTrack>> _cachedTracks = {};
  static Map<String, DateTime> _cacheTimestamps = {};

  /// Search for tracks by category/genre
  static Future<List<MusicTrack>> _fetchTracksByCategory(String category) async {
    try {
      // Map categories to music genres/search terms
      final searchTerm = _mapCategoryToMusicTerm(category);
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'term': searchTerm,
        'media': 'music',
        'entity': 'song',
        'limit': '100', // Increased limit to get more diverse results
        'country': 'US',
        'explicit': 'No', // Family-friendly content
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final searchResponse = MusicSearchResponse.fromJson(json.decode(response.body));
        
        // Filter and ensure unique tracks
        final validTracks = searchResponse.results
            .where((track) => track.previewUrl.isNotEmpty)
            .toList();
        
        // Remove duplicates based on track name and artist
        final uniqueTracks = <String, MusicTrack>{};
        for (final track in validTracks) {
          final key = '${track.trackName.toLowerCase()}_${track.artistName.toLowerCase()}';
          if (!uniqueTracks.containsKey(key)) {
            uniqueTracks[key] = track;
          }
        }
        
        final uniqueTracksList = uniqueTracks.values.toList();
        
        if (uniqueTracksList.length >= 3) {
          uniqueTracksList.shuffle();
          return uniqueTracksList.take(3).toList();
        } else {
          return uniqueTracksList;
        }
      } else {
        throw Exception('Failed to fetch tracks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tracks for category $category: $e');
      return [];
    }
  }

  /// Get popular tracks as fallback
  static Future<List<MusicTrack>> _getPopularTracks() async {
    try {
      // Try multiple search terms to get diverse results
      final searchTerms = ['popular music', 'top hits', 'trending songs'];
      final allTracks = <MusicTrack>[];
      
      for (final term in searchTerms) {
        final tracks = await _fetchTracksByCategory(term);
        allTracks.addAll(tracks);
        
        if (allTracks.length >= 10) break; // Get enough tracks for selection
      }
      
      // Remove duplicates
      final uniqueTracks = <String, MusicTrack>{};
      for (final track in allTracks) {
        final key = '${track.trackName.toLowerCase()}_${track.artistName.toLowerCase()}';
        if (!uniqueTracks.containsKey(key)) {
          uniqueTracks[key] = track;
        }
      }
      
      final uniqueTracksList = uniqueTracks.values.toList();
      uniqueTracksList.shuffle();
      
      return uniqueTracksList.take(3).toList();
    } catch (e) {
      print('Error getting popular tracks: $e');
      return [];
    }
  }

  /// Get 3 music tracks based on user's selected categories
  static Future<List<MusicTrack>> getRecommendedTracks() async {
    try {
      final userCategories = await _getUserSelectedCategories();
      
      if (userCategories.isEmpty) {
        // Return popular tracks if no categories selected
        return await _getPopularTracks();
      }

      // Use date-based seed for consistent daily recommendations
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final randomGenerator = math.Random(today.hashCode);
      
      // Try multiple categories to get diverse tracks
      final allTracks = <MusicTrack>[];
      final maxCategoriesToTry = math.min(3, userCategories.length);
      
      // Shuffle categories and try multiple ones
      final shuffledCategories = List<String>.from(userCategories);
      shuffledCategories.shuffle(randomGenerator);
      
      for (int i = 0; i < maxCategoriesToTry; i++) {
        final selectedCategory = shuffledCategories[i];
        
        // Check cache first
        final cacheKey = '${selectedCategory}_$today';
        if (_cachedTracks.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
          allTracks.addAll(_cachedTracks[cacheKey]!);
        } else {
          // Fetch new tracks
          final tracks = await _fetchTracksByCategory(selectedCategory);
          if (tracks.isNotEmpty) {
            // Cache the results
            _cachedTracks[cacheKey] = tracks;
            _cacheTimestamps[cacheKey] = DateTime.now();
            allTracks.addAll(tracks);
          }
        }
        
        if (allTracks.length >= 10) break; // Get enough for selection
      }
      
      // Remove duplicates and select 3 different tracks
      final uniqueTracks = <String, MusicTrack>{};
      for (final track in allTracks) {
        final key = '${track.trackName.toLowerCase()}_${track.artistName.toLowerCase()}';
        if (!uniqueTracks.containsKey(key)) {
          uniqueTracks[key] = track;
        }
      }
      
      final uniqueTracksList = uniqueTracks.values.toList();
      uniqueTracksList.shuffle(randomGenerator);
      
      final finalTracks = uniqueTracksList.take(3).toList();
      
      // If still not enough unique tracks, fill with popular tracks
      if (finalTracks.length < 3) {
        final popularTracks = await _getPopularTracks();
        for (final track in popularTracks) {
          final key = '${track.trackName.toLowerCase()}_${track.artistName.toLowerCase()}';
          if (!uniqueTracks.containsKey(key) && finalTracks.length < 3) {
            finalTracks.add(track);
            uniqueTracks[key] = track;
          }
        }
      }
      
      return finalTracks;
    } catch (e) {
      print('Error getting recommended tracks: $e');
      return _getCachedTracksOrEmpty();
    }
  }

  /// Map user categories to music search terms
  static String _mapCategoryToMusicTerm(String category) {
    final categoryMap = {
      'technology': 'electronic music',
      'science': 'ambient instrumental',
      'history': 'classical music',
      'philosophy': 'meditation ambient',
      'art': 'indie alternative',
      'music': 'popular hits',
      'literature': 'folk acoustic',
      'psychology': 'relaxing piano',
      'business': 'motivational instrumental',
      'health': 'wellness meditation',
      'politics': 'world music',
      'sports': 'energetic workout',
    };
    
    return categoryMap[category.toLowerCase()] ?? 'popular music';
  }

  /// Get user's selected categories from SharedPreferences
  static Future<List<String>> _getUserSelectedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedCategories = prefs.getStringList('selected_categories') ?? [];
      
      return selectedCategories
          .map((category) => category.toLowerCase())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if cache is valid for a category
  static bool _isCacheValid(String cacheKey) {
    if (!_cachedTracks.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheValidDuration;
  }

  /// Get cached tracks or return empty list
  static List<MusicTrack> _getCachedTracksOrEmpty() {
    if (_cachedTracks.isNotEmpty) {
      return _cachedTracks.values.first;
    }
    return [];
  }

  /// Search tracks by custom term
  static Future<List<MusicTrack>> searchTracks(String searchTerm, {int limit = 20}) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'term': searchTerm,
        'media': 'music',
        'entity': 'song',
        'limit': limit.toString(),
        'country': 'US',
        'explicit': 'No',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final searchResponse = MusicSearchResponse.fromJson(json.decode(response.body));
        return searchResponse.results;
      } else {
        throw Exception('Failed to search tracks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }

  /// Clear cache
  static void clearCache() {
    _cachedTracks.clear();
    _cacheTimestamps.clear();
  }
}
