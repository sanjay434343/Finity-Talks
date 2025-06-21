import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'wikipedia_service.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finitytalks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        duration TEXT NOT NULL,
        image_url TEXT,
        page_url TEXT NOT NULL,
        cached_date TEXT NOT NULL,
        date_fetched TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // Check if cached episodes are still valid (within 24 hours and same day)
  Future<bool> areCachedEpisodesValid() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get the last fetch date
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['last_episode_fetch'],
      );

      if (result.isEmpty) return false;

      final lastFetchStr = result.first['value'] as String;
      final lastFetch = DateTime.parse(lastFetchStr);
      final lastFetchDate = DateTime(lastFetch.year, lastFetch.month, lastFetch.day);

      // Check if it's the same day and within 24 hours
      final isWithin24Hours = now.difference(lastFetch).inHours < 24;
      final isSameDay = today.isAtSameMomentAs(lastFetchDate);

      if (kDebugMode) {
        print('Cache validation - Last fetch: $lastFetch');
        print('Cache validation - Within 24h: $isWithin24Hours, Same day: $isSameDay');
      }

      return isWithin24Hours && isSameDay;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking cache validity: $e');
      }
      return false;
    }
  }

  // Get cached episodes if they're still valid
  Future<List<WikipediaEpisode>?> getCachedEpisodes() async {
    try {
      if (!await areCachedEpisodesValid()) {
        if (kDebugMode) {
          print('Cached episodes are expired, returning null');
        }
        return null;
      }

      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('episodes');

      if (maps.isEmpty) return null;

      final episodes = maps.map((map) => WikipediaEpisode(
        title: map['title'],
        description: map['description'],
        category: map['category'],
        duration: map['duration'],
        imageUrl: map['image_url'],
        pageUrl: map['page_url'] ?? 'https://en.wikipedia.org',
      )).toList();

      if (kDebugMode) {
        print('Retrieved ${episodes.length} cached episodes');
      }

      return episodes;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached episodes: $e');
      }
      return null;
    }
  }

  // Cache new episodes
  Future<void> cacheEpisodes(List<WikipediaEpisode> episodes) async {
    try {
      final db = await database;
      final now = DateTime.now();

      // Clear existing episodes
      await db.delete('episodes');

      // Insert new episodes
      for (final episode in episodes) {
        await db.insert(
          'episodes',
          {
            'title': episode.title,
            'description': episode.description,
            'category': episode.category,
            'duration': episode.duration,
            'image_url': episode.imageUrl,
            'page_url': episode.pageUrl,
            'cached_date': now.toIso8601String(),
            'date_fetched': now.toIso8601String(),
          },
        );
      }

      // Update last fetch time
      await db.insert(
        'app_settings',
        {
          'key': 'last_episode_fetch',
          'value': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        print('Cached ${episodes.length} episodes at $now');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching episodes: $e');
      }
    }
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    try {
      if (!await areCachedEpisodesValid()) {
        final db = await database;
        await db.delete('episodes');
        await db.delete('app_settings', where: 'key = ?', whereArgs: ['last_episode_fetch']);
        
        if (kDebugMode) {
          print('Cleared expired cache');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing expired cache: $e');
      }
    }
  }

  // Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final db = await database;
      
      final episodeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM episodes')
      ) ?? 0;

      final lastFetchResult = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['last_episode_fetch'],
      );

      String? lastFetch;
      if (lastFetchResult.isNotEmpty) {
        lastFetch = lastFetchResult.first['value'] as String;
      }

      return {
        'episode_count': episodeCount,
        'last_fetch': lastFetch,
        'is_valid': await areCachedEpisodesValid(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cache info: $e');
      }
      return {
        'episode_count': 0,
        'last_fetch': null,
        'is_valid': false,
      };
    }
  }

  // Clear all data (for debugging/reset)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('episodes');
      await db.delete('app_settings');
      
      if (kDebugMode) {
        print('Cleared all database data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all data: $e');
      }
    }
  }
}
