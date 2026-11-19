import 'package:sqflite/sqflite.dart';

import '../../core/app_logger.dart';
import '../../core/database_helper.dart';
import '../models/user_goals.dart';

abstract class GoalsRepository {
  Future<UserGoals?> getGoals();
  Future<void> saveGoals(UserGoals goals);
}

class SqliteGoalsRepository implements GoalsRepository {
  final DatabaseHelper _dbHelper;

  SqliteGoalsRepository(this._dbHelper);

  @override
  Future<UserGoals?> getGoals() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user_goals',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserGoals.fromDbMap(rows.first);
  }

  @override
  Future<void> saveGoals(UserGoals goals) async {
    final db = await _dbHelper.database;
    await db.insert(
      'user_goals',
      goals.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.info(
      'Сохранена норма КБЖУ (режим: ${goals.isManual ? "ручной" : "авто"})',
    );
  }
}