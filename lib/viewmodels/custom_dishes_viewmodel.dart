import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';
import '../core/load_state.dart';
import '../data/models/food_item.dart';
import '../data/repositories/food_repository.dart';

class CustomDishesViewModel extends ChangeNotifier {
  final FoodRepository _repository;

  LoadState _state = LoadState.idle;
  List<FoodItem> _dishes = [];
  String _filterQuery = '';
  String? _errorMessage;

  CustomDishesViewModel(this._repository);

  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  String get filterQuery => _filterQuery;
  List<FoodItem> get allDishes => List.unmodifiable(_dishes);

  List<FoodItem> get filteredDishes {
    if (_filterQuery.trim().isEmpty) {
      return List.unmodifiable(_dishes);
    }
    final q = _filterQuery.trim().toLowerCase();
    return _dishes.where((dish) {
      final nameMatch = dish.name.toLowerCase().contains(q);
      final brandMatch = (dish.brand ?? '').toLowerCase().contains(q);
      return nameMatch || brandMatch;
    }).toList();
  }

  void setFilterQuery(String value) {
    _filterQuery = value;
    notifyListeners();
  }

  Future<void> loadDishes() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _dishes = await _repository.getCustomDishes();
      _state = LoadState.success;
    } catch (e, st) {
      AppLogger.error('Ошибка загрузки своих блюд', e, st);
      _errorMessage = 'Не удалось загрузить список блюд.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> addDish(FoodItem dish) async {
    try {
      await _repository.addCustomDish(dish.copyWith(isCustom: true));
      await loadDishes();
      return true;
    } catch (e, st) {
      AppLogger.error('Ошибка создания своего блюда', e, st);
      _errorMessage = 'Не удалось сохранить блюдо.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDish(FoodItem dish) async {
    try {
      await _repository.updateCustomDish(dish.copyWith(isCustom: true));
      await loadDishes();
      return true;
    } catch (e, st) {
      AppLogger.error('Ошибка редактирования своего блюда', e, st);
      _errorMessage = 'Не удалось обновить блюдо.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDish(int id) async {
    try {
      await _repository.deleteCustomDish(id);
      await loadDishes();
    } catch (e, st) {
      AppLogger.error('Ошибка удаления своего блюда', e, st);
      _errorMessage = 'Не удалось удалить блюдо.';
      notifyListeners();
    }
  }
}