import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'app_logger.dart';

class DatabaseHelper {
  static const String _dbName = 'kbzhu_diary.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    AppLogger.info('Инициализация базы данных SQLite');

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Создание таблиц базы данных (версия $version)');

    await db.execute('''
      CREATE TABLE user_goals (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        height_cm REAL NOT NULL,
        weight_kg REAL NOT NULL,
        activity_level TEXT NOT NULL,
        goal_type TEXT NOT NULL,
        is_manual INTEGER NOT NULL,
        target_calories INTEGER NOT NULL,
        target_protein INTEGER NOT NULL,
        target_fat INTEGER NOT NULL,
        target_carbs INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_dishes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        barcode TEXT,
        calories_per_100g REAL NOT NULL,
        protein_per_100g REAL NOT NULL,
        fat_per_100g REAL NOT NULL,
        carbs_per_100g REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        grams REAL NOT NULL,
        calories_per_100g REAL NOT NULL,
        protein_per_100g REAL NOT NULL,
        fat_per_100g REAL NOT NULL,
        carbs_per_100g REAL NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');
  }
}