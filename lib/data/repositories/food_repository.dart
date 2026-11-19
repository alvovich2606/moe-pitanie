import '../../core/app_logger.dart';
import '../../core/database_helper.dart';
import '../models/food_item.dart';
import '../services/open_food_facts_service.dart';

abstract class FoodRepository {
  Future<List<FoodItem>> getCustomDishes();
  Future<int> addCustomDish(FoodItem dish);
  Future<void> updateCustomDish(FoodItem dish);
  Future<void> deleteCustomDish(int id);
  Future<List<FoodItem>> searchApi(String query);
  Future<FoodItem?> getByBarcode(String barcode);
}

class AppFoodRepository implements FoodRepository {
  final DatabaseHelper _dbHelper;
  final OpenFoodFactsService _apiService;

  AppFoodRepository(this._dbHelper, this._apiService);

  @override
  Future<List<FoodItem>> getCustomDishes() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'custom_dishes',
      orderBy: 'id DESC',
    );
    return rows.map(FoodItem.fromDbMap).toList();
  }

  @override
  Future<int> addCustomDish(FoodItem dish) async {
    final db = await _dbHelper.database;
    final id = await db.insert('custom_dishes', dish.toDbMap());
    AppLogger.info('Добавлено своё блюдо (id: $id)');
    return id;
  }

  @override
  Future<void> updateCustomDish(FoodItem dish) async {
    if (dish.id == null) return;
    final db = await _dbHelper.database;
    await db.update(
      'custom_dishes',
      dish.toDbMap(),
      where: 'id = ?',
      whereArgs: [dish.id],
    );
    AppLogger.info('Обновлено своё блюдо (id: ${dish.id})');
  }

  @override
  Future<void> deleteCustomDish(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'custom_dishes',
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.info('Удалено своё блюдо (id: $id)');
  }

  @override
  Future<List<FoodItem>> searchApi(String query) {
    return _apiService.searchProducts(query);
  }

  @override
  Future<FoodItem?> getByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final localRows = await db.query(
      'custom_dishes',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
      limit: 1,
    );

    if (localRows.isNotEmpty) {
      AppLogger.info('Продукт по штрихкоду найден в своих блюдах');
      return FoodItem.fromDbMap(localRows.first);
    }

    return _apiService.getProductByBarcode(barcode);
  }
}