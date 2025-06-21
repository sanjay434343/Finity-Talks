import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/favorite_item.dart';

class FavoritesDatabase {
  static final FavoritesDatabase _instance = FavoritesDatabase._internal();
  factory FavoritesDatabase() => _instance;
  FavoritesDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'favorites.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_type ON favorites(type)');
    await db.execute('CREATE INDEX idx_created_at ON favorites(created_at DESC)');
  }

  // Add a favorite item
  Future<int> addFavorite(FavoriteItem item) async {
    final db = await database;
    final map = item.toMap();
    map['data'] = jsonEncode(map['data']); // Convert data map to JSON string
    return await db.insert('favorites', map);
  }

  // Remove a favorite item
  Future<int> removeFavorite(int id) async {
    final db = await database;
    return await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // Check if an item is favorited
  Future<bool> isFavorited(String title, String type) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'title = ? AND type = ?',
      whereArgs: [title, type],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Get favorite by title and type
  Future<FavoriteItem?> getFavoriteByTitle(String title, String type) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'title = ? AND type = ?',
      whereArgs: [title, type],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    
    final map = Map<String, dynamic>.from(result.first);
    map['data'] = jsonDecode(map['data'] as String);
    return FavoriteItem.fromMap(map);
  }

  // Get all favorites
  Future<List<FavoriteItem>> getAllFavorites() async {
    final db = await database;
    final result = await db.query('favorites', orderBy: 'created_at DESC');
    
    return result.map((map) {
      final itemMap = Map<String, dynamic>.from(map);
      itemMap['data'] = jsonDecode(itemMap['data'] as String);
      return FavoriteItem.fromMap(itemMap);
    }).toList();
  }

  // Get favorites by type
  Future<List<FavoriteItem>> getFavoritesByType(String type) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
    
    return result.map((map) {
      final itemMap = Map<String, dynamic>.from(map);
      itemMap['data'] = jsonDecode(itemMap['data'] as String);
      return FavoriteItem.fromMap(itemMap);
    }).toList();
  }

  // Get favorites count
  Future<int> getFavoritesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM favorites');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get favorites count by type
  Future<int> getFavoritesCountByType(String type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM favorites WHERE type = ?',
      [type],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Clear all favorites
  Future<int> clearAllFavorites() async {
    final db = await database;
    return await db.delete('favorites');
  }

  // Clear favorites by type
  Future<int> clearFavoritesByType(String type) async {
    final db = await database;
    return await db.delete('favorites', where: 'type = ?', whereArgs: [type]);
  }
}
