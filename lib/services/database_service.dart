import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _userCategoriesPrefix = 'user_categories_';
  static const String _savedEpisodesPrefix = 'saved_episodes_';
  static const String _userPreferencesPrefix = 'user_preferences_';

  // Get user's preferred categories from SharedPreferences
  Future<List<String>> getUserCategories(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString('$_userCategoriesPrefix$userId');
      
      if (categoriesJson != null) {
        final List<dynamic> categoriesList = json.decode(categoriesJson);
        return categoriesList.cast<String>();
      }
      
      // Return default categories if none saved
      final defaultCategories = ['Science', 'Technology', 'History', 'Nature', 'Culture'];
      
      // Save default categories for future use
      await saveUserCategories(userId, defaultCategories);
      
      return defaultCategories;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user categories: $e');
      }
      return ['Science', 'Technology', 'History', 'Nature', 'Culture'];
    }
  }

  // Save user's preferred categories to SharedPreferences
  Future<void> saveUserCategories(String userId, List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(categories);
      await prefs.setString('$_userCategoriesPrefix$userId', categoriesJson);
      
      if (kDebugMode) {
        print('Saved user categories: $categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user categories: $e');
      }
    }
  }

  // Add a category to user's preferences
  Future<void> addUserCategory(String userId, String category) async {
    try {
      final currentCategories = await getUserCategories(userId);
      if (!currentCategories.contains(category)) {
        currentCategories.add(category);
        await saveUserCategories(userId, currentCategories);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding user category: $e');
      }
    }
  }

  // Remove a category from user's preferences
  Future<void> removeUserCategory(String userId, String category) async {
    try {
      final currentCategories = await getUserCategories(userId);
      currentCategories.remove(category);
      await saveUserCategories(userId, currentCategories);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing user category: $e');
      }
    }
  }

  // Get all available categories
  Future<List<String>> getAvailableCategories() async {
    return [
      'Science',
      'Technology', 
      'History',
      'Nature',
      'Culture',
      'Geography',
      'Philosophy',
      'Art',
      'Music',
      'Literature',
      'Politics',
      'Economics',
      'Sports',
      'Health',
      'Psychology'
    ];
  }

  // Save episode to user's saved list in SharedPreferences
  Future<void> saveEpisode(String userId, Map<String, dynamic> episode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEpisodesJson = prefs.getString('$_savedEpisodesPrefix$userId') ?? '[]';
      final List<dynamic> savedEpisodes = json.decode(savedEpisodesJson);
      
      // Check if episode already exists
      final exists = savedEpisodes.any((ep) => ep['title'] == episode['title']);
      if (!exists) {
        episode['savedAt'] = DateTime.now().toIso8601String();
        savedEpisodes.add(episode);
        await prefs.setString('$_savedEpisodesPrefix$userId', json.encode(savedEpisodes));
        
        if (kDebugMode) {
          print('Episode saved: ${episode['title']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving episode: $e');
      }
    }
  }

  // Get user's saved episodes from SharedPreferences
  Future<List<Map<String, dynamic>>> getSavedEpisodes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEpisodesJson = prefs.getString('$_savedEpisodesPrefix$userId') ?? '[]';
      final List<dynamic> savedEpisodes = json.decode(savedEpisodesJson);
      
      // Sort by saved date (most recent first)
      final episodes = savedEpisodes.cast<Map<String, dynamic>>();
      episodes.sort((a, b) {
        final aDate = DateTime.tryParse(a['savedAt'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['savedAt'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      return episodes;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved episodes: $e');
      }
      return [];
    }
  }

  // Remove episode from saved list in SharedPreferences
  Future<void> removeSavedEpisode(String userId, String episodeTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEpisodesJson = prefs.getString('$_savedEpisodesPrefix$userId') ?? '[]';
      final List<dynamic> savedEpisodes = json.decode(savedEpisodesJson);
      
      savedEpisodes.removeWhere((ep) => ep['title'] == episodeTitle);
      await prefs.setString('$_savedEpisodesPrefix$userId', json.encode(savedEpisodes));
      
      if (kDebugMode) {
        print('Episode removed: $episodeTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing saved episode: $e');
      }
    }
  }

  // Check if episode is saved
  Future<bool> isEpisodeSaved(String userId, String episodeTitle) async {
    try {
      final savedEpisodes = await getSavedEpisodes(userId);
      return savedEpisodes.any((ep) => ep['title'] == episodeTitle);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if episode is saved: $e');
      }
      return false;
    }
  }

  // Save user preferences (theme, language, etc.)
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = json.encode(preferences);
      await prefs.setString('$_userPreferencesPrefix$userId', preferencesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user preferences: $e');
      }
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('$_userPreferencesPrefix$userId');
      
      if (preferencesJson != null) {
        return json.decode(preferencesJson);
      }
      
      // Return default preferences
      final defaultPreferences = {
        'theme': 'light',
        'language': 'en',
        'notifications': true,
        'autoPlay': false,
        'downloadOverWifiOnly': true,
      };
      
      await saveUserPreferences(userId, defaultPreferences);
      return defaultPreferences;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user preferences: $e');
      }
      return {
        'theme': 'light',
        'language': 'en',
        'notifications': true,
        'autoPlay': false,
        'downloadOverWifiOnly': true,
      };
    }
  }

  // Clear all user data from SharedPreferences
  Future<void> clearUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_userCategoriesPrefix$userId');
      await prefs.remove('$_savedEpisodesPrefix$userId');
      await prefs.remove('$_userPreferencesPrefix$userId');
      
      if (kDebugMode) {
        print('User data cleared for: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user data: $e');
      }
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final savedEpisodes = await getSavedEpisodes(userId);
      final categories = await getUserCategories(userId);
      
      // Count episodes by category
      final categoryCount = <String, int>{};
      for (final episode in savedEpisodes) {
        final category = episode['category'] ?? 'Unknown';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
      
      return {
        'totalSavedEpisodes': savedEpisodes.length,
        'totalCategories': categories.length,
        'favoriteCategory': categoryCount.isNotEmpty 
            ? categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key.hashCode
            : 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user stats: $e');
      }
      return {
        'totalSavedEpisodes': 0,
        'totalCategories': 0,
        'favoriteCategory': 0,
      };
    }
  }
}
