import '../../core/app_logger.dart';
import '../../core/database_helper.dart';
import '../models/meal.dart';
import '../models/meal_entry.dart';

abstract class DiaryRepository {
  Future<List<Meal>> getMealsForDate(String date);
  Future<int> addMeal(String date, String name);
  Future<void> renameMeal(int mealId, String newName);
  Future<void> deleteMeal(int mealId);
  Future<int> addEntry(MealEntry entry);
  Future<void> updateEntryGrams(int entryId, double grams);
  Future<void> deleteEntry(int entryId);
}

class SqliteDiaryRepository implements DiaryRepository {
  final DatabaseHelper _dbHelper;

  static const List<String> _defaultMealNames = [
    'Завтрак',
    'Обед',
    'Ужин',
    'Перекус',
  ];

  SqliteDiaryRepository(this._dbHelper);

  @override
  Future<List<Meal>> getMealsForDate(String date) async {
    final db = await _dbHelper.database;

    var mealRows = await db.query(
      'meals',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'sort_order ASC, id ASC',
    );

    if (mealRows.isEmpty) {
      for (var i = 0; i < _defaultMealNames.length; i++) {
        await db.insert('meals', {
          'date': date,
          'name': _defaultMealNames[i],
          'sort_order': i,
        });
      }
      mealRows = await db.query(
        'meals',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'sort_order ASC, id ASC',
      );
      AppLogger.info('Созданы базовые приёмы пищи на дату $date');
    }

    final meals = <Meal>[];
    for (final row in mealRows) {
      final mealId = row['id'] as int;
      final entryRows = await db.query(
        'meal_entries',
        where: 'meal_id = ?',
        whereArgs: [mealId],
        orderBy: 'id ASC',
      );
      final entries = entryRows.map(MealEntry.fromDbMap).toList();
      meals.add(Meal.fromDbMap(row, entries: entries));
    }

    return meals;
  }

  @override
  Future<int> addMeal(String date, String name) async {
    final db = await _dbHelper.database;
    final countResult = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS max_order FROM meals WHERE date = ?',
      [date],
    );
    final nextOrder = ((countResult.first['max_order'] as int?) ?? -1) + 1;

    final id = await db.insert('meals', {
      'date': date,
      'name': name.trim(),
      'sort_order': nextOrder,
    });
    AppLogger.info('Добавлен приём пищи (id: $id)');
    return id;
  }

  @override
  Future<void> renameMeal(int mealId, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
      'meals',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [mealId],
    );
    AppLogger.info('Переименован приём пищи (id: $mealId)');
  }

  @override
  Future<void> deleteMeal(int mealId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [mealId],
    );
    AppLogger.info('Удалён приём пищи (id: $mealId)');
  }

  @override
  Future<int> addEntry(MealEntry entry) async {
    final db = await _dbHelper.database;
    final id = await db.insert('meal_entries', entry.toDbMap());
    AppLogger.info('Добавлена запись в дневник (id: $id, mealId: ${entry.mealId})');
    return id;
  }

  @override
  Future<void> updateEntryGrams(int entryId, double grams) async {
    final db = await _dbHelper.database;
    await db.update(
      'meal_entries',
      {'grams': grams},
      where: 'id = ?',
      whereArgs: [entryId],
    );
    AppLogger.info('Обновлена граммовка записи (id: $entryId)');
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'meal_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
    AppLogger.info('Удалена запись из дневника (id: $entryId)');
  }
}