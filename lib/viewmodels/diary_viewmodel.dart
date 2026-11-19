import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/app_logger.dart';
import '../core/load_state.dart';
import '../data/models/food_item.dart';
import '../data/models/meal.dart';
import '../data/models/meal_entry.dart';
import '../data/repositories/diary_repository.dart';

class DiaryViewModel extends ChangeNotifier {
  final DiaryRepository _repository;

  LoadState _state = LoadState.idle;
  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [];
  String? _errorMessage;

  DiaryViewModel(this._repository);

  LoadState get state => _state;
  DateTime get selectedDate => _selectedDate;
  String get formattedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  List<Meal> get meals => List.unmodifiable(_meals);
  String? get errorMessage => _errorMessage;

  double get totalCalories =>
      _meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);

  double get totalProtein =>
      _meals.fold(0.0, (sum, meal) => sum + meal.totalProtein);

  double get totalFat => _meals.fold(0.0, (sum, meal) => sum + meal.totalFat);

  double get totalCarbs =>
      _meals.fold(0.0, (sum, meal) => sum + meal.totalCarbs);

  Future<void> loadDiary() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _meals = await _repository.getMealsForDate(formattedDateKey);
      _state = LoadState.success;
    } catch (e, st) {
      AppLogger.error('Ошибка загрузки дневника', e, st);
      _errorMessage = 'Не удалось загрузить дневник питания.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> changeDate(DateTime newDate) async {
    _selectedDate = newDate;
    await loadDiary();
  }

  Future<void> previousDay() async {
    await changeDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> nextDay() async {
    await changeDate(_selectedDate.add(const Duration(days: 1)));
  }

  Future<void> addMeal(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      await _repository.addMeal(formattedDateKey, trimmed);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка добавления приёма пищи', e, st);
      _errorMessage = 'Не удалось добавить приём пищи.';
      notifyListeners();
    }
  }

  Future<void> renameMeal(int mealId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    try {
      await _repository.renameMeal(mealId, trimmed);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка переименования приёма пищи', e, st);
      _errorMessage = 'Не удалось переименовать приём пищи.';
      notifyListeners();
    }
  }

  Future<void> deleteMeal(int mealId) async {
    try {
      await _repository.deleteMeal(mealId);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка удаления приёма пищи', e, st);
      _errorMessage = 'Не удалось удалить приём пищи.';
      notifyListeners();
    }
  }

  Future<void> addFoodToMeal({
    required int mealId,
    required FoodItem food,
    required double grams,
  }) async {
    if (grams <= 0) return;

    try {
      final entry = MealEntry(
        mealId: mealId,
        foodName: food.name,
        grams: grams,
        caloriesPer100g: food.caloriesPer100g,
        proteinPer100g: food.proteinPer100g,
        fatPer100g: food.fatPer100g,
        carbsPer100g: food.carbsPer100g,
      );
      await _repository.addEntry(entry);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка добавления продукта в приём пищи', e, st);
      _errorMessage = 'Не удалось добавить продукт.';
      notifyListeners();
    }
  }

  Future<void> updateEntryGrams(int entryId, double grams) async {
    if (grams <= 0) return;

    try {
      await _repository.updateEntryGrams(entryId, grams);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка обновления граммовки', e, st);
      _errorMessage = 'Не удалось обновить граммовку.';
      notifyListeners();
    }
  }

  Future<void> deleteEntry(int entryId) async {
    try {
      await _repository.deleteEntry(entryId);
      await loadDiary();
    } catch (e, st) {
      AppLogger.error('Ошибка удаления записи', e, st);
      _errorMessage = 'Не удалось удалить запись.';
      notifyListeners();
    }
  }
}