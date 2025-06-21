import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';
import '../services/favorites_database.dart';
import '../services/wikipedia_service.dart';
import '../services/nasa_service.dart';
import '../screens/book_detail_page.dart';

class FavoritesService {
  static final FavoritesDatabase _db = FavoritesDatabase();

  // Book favorites
  static Future<bool> toggleBookFavorite(BookSuggestion book, String about, List<String> subjects) async {
    final isCurrentlyFavorited = await _db.isFavorited(book.title, 'book');
    
    if (isCurrentlyFavorited) {
      final existingFavorite = await _db.getFavoriteByTitle(book.title, 'book');
      if (existingFavorite != null) {
        await _db.removeFavorite(existingFavorite.id!);
        return false;
      }
    } else {
      final favoriteBook = FavoriteBook(
        title: book.title,
        imageUrl: book.coverUrl,
        author: book.author,
        about: about,
        subjects: subjects,
        key: book.key,
      );
      await _db.addFavorite(favoriteBook);
      return true;
    }
    return false;
  }

  static Future<bool> isBookFavorited(String title) async {
    return await _db.isFavorited(title, 'book');
  }

  // Podcast favorites
  static Future<bool> togglePodcastFavorite(WikipediaEpisode episode) async {
    final isCurrentlyFavorited = await _db.isFavorited(episode.title, 'podcast');
    
    if (isCurrentlyFavorited) {
      final existingFavorite = await _db.getFavoriteByTitle(episode.title, 'podcast');
      if (existingFavorite != null) {
        await _db.removeFavorite(existingFavorite.id!);
        return false;
      }
    } else {
      final favoritePodcast = FavoritePodcast(
        title: episode.title,
        imageUrl: episode.imageUrl ?? '',
        content: episode.description,
        category: episode.category,
        pageUrl: episode.pageUrl,
        duration: episode.duration,
      );
      await _db.addFavorite(favoritePodcast);
      return true;
    }
    return false;
  }

  static Future<bool> isPodcastFavorited(String title) async {
    return await _db.isFavorited(title, 'podcast');
  }

  // Space image favorites
  static Future<bool> toggleSpaceImageFavorite(
    String title,
    String imageUrl,
    String content,
    String detail,
    String date, {
    String source = 'NASA',
    String type = 'APOD',
    String quality = 'HD',
  }) async {
    final isCurrentlyFavorited = await _db.isFavorited(title, 'space');
    
    if (isCurrentlyFavorited) {
      final existingFavorite = await _db.getFavoriteByTitle(title, 'space');
      if (existingFavorite != null) {
        await _db.removeFavorite(existingFavorite.id!);
        return false;
      }
    } else {
      final favoriteSpace = FavoriteSpaceImage(
        title: title,
        imageUrl: imageUrl,
        content: content,
        detail: detail,
        source: source,
        date: date,
        type: type,
        quality: quality,
      );
      await _db.addFavorite(favoriteSpace);
      return true;
    }
    return false;
  }

  static Future<bool> isSpaceImageFavorited(String title) async {
    return await _db.isFavorited(title, 'space');
  }

  // Get all favorites
  static Future<List<FavoriteItem>> getAllFavorites() async {
    return await _db.getAllFavorites();
  }

  // Get favorites by type
  static Future<List<FavoriteBook>> getFavoriteBooks() async {
    final favorites = await _db.getFavoritesByType('book');
    return favorites.map((item) => FavoriteBook(
      id: item.id,
      title: item.title,
      imageUrl: item.imageUrl,
      author: item.data['author'],
      about: item.data['about'],
      subjects: List<String>.from(item.data['subjects']),
      key: item.data['key'],
      createdAt: item.createdAt,
    )).toList();
  }

  static Future<List<FavoritePodcast>> getFavoritePodcasts() async {
    final favorites = await _db.getFavoritesByType('podcast');
    return favorites.map((item) => FavoritePodcast(
      id: item.id,
      title: item.title,
      imageUrl: item.imageUrl,
      content: item.data['content'],
      category: item.data['category'],
      pageUrl: item.data['page_url'],
      duration: item.data['duration'],
      createdAt: item.createdAt,
    )).toList();
  }

  static Future<List<FavoriteSpaceImage>> getFavoriteSpaceImages() async {
    final favorites = await _db.getFavoritesByType('space');
    return favorites.map((item) => FavoriteSpaceImage(
      id: item.id,
      title: item.title,
      imageUrl: item.imageUrl,
      content: item.data['content'],
      detail: item.data['detail'],
      source: item.data['source'],
      date: item.data['date'],
      type: item.data['image_type'],
      quality: item.data['quality'],
      createdAt: item.createdAt,
    )).toList();
  }

  static Future<List<FavoriteMusic>> getFavoriteMusic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> musicJson = prefs.getStringList('favorite_music') ?? [];
      
      return musicJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return FavoriteMusic.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading favorite music: $e');
      return [];
    }
  }

  static Future<void> saveFavoriteMusic(FavoriteMusic music) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentMusic = prefs.getStringList('favorite_music') ?? [];
      
      // Check if already exists
      final exists = currentMusic.any((json) {
        final data = jsonDecode(json);
        return data['title'] == music.title && data['artist'] == music.artist;
      });
      
      if (!exists) {
        currentMusic.add(jsonEncode(music.toJson()));
        await prefs.setStringList('favorite_music', currentMusic);
      }
    } catch (e) {
      print('Error saving favorite music: $e');
    }
  }

  static Future<void> removeFavoriteMusic(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentMusic = prefs.getStringList('favorite_music') ?? [];
      
      currentMusic.removeWhere((json) {
        final data = jsonDecode(json);
        return data['title'] == title && data['artist'] == artist;
      });
      
      await prefs.setStringList('favorite_music', currentMusic);
    } catch (e) {
      print('Error removing favorite music: $e');
    }
  }

  static Future<bool> isMusicFavorited(String title, String artist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentMusic = prefs.getStringList('favorite_music') ?? [];
      
      return currentMusic.any((json) {
        final data = jsonDecode(json);
        return data['title'] == title && data['artist'] == artist;
      });
    } catch (e) {
      print('Error checking if music is favorited: $e');
      return false;
    }
  }

  // Get counts
  static Future<int> getTotalFavoritesCount() async {
    return await _db.getFavoritesCount();
  }

  static Future<int> getFavoritesBooksCount() async {
    return await _db.getFavoritesCountByType('book');
  }

  static Future<int> getFavoritesPodcastsCount() async {
    return await _db.getFavoritesCountByType('podcast');
  }

  static Future<int> getFavoritesSpaceImagesCount() async {
    return await _db.getFavoritesCountByType('space');
  }
}
