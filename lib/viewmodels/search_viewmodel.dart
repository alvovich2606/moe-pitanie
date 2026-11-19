import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';
import '../core/load_state.dart';
import '../data/models/food_item.dart';
import '../data/repositories/food_repository.dart';
import '../data/services/open_food_facts_service.dart';

enum SearchSourceFilter {
  all,
  api,
  custom,
}

class SearchViewModel extends ChangeNotifier {
  final FoodRepository _repository;

  LoadState _state = LoadState.idle;
  List<FoodItem> _customDishes = [];
  List<FoodItem> _apiResults = [];
  SearchSourceFilter _sourceFilter = SearchSourceFilter.all;
  String _lastSearchQuery = '';
  String _listFilterQuery = '';
  String? _errorMessage;

  SearchViewModel(this._repository);

  LoadState get state => _state;
  SearchSourceFilter get sourceFilter => _sourceFilter;
  String get lastSearchQuery => _lastSearchQuery;
  String get listFilterQuery => _listFilterQuery;
  String? get errorMessage => _errorMessage;
  int get customDishesCount => _customDishes.length;

  /// Пользовательские блюда всегда отображаются первыми.
  /// Продукты с 0 ккал исключаются, максимум 50 позиций на выводе.
  List<FoodItem> get results {
    final queryLower =
        _lastSearchQuery.trim().toLowerCase().replaceAll('ё', 'е');
    final filterLower =
        _listFilterQuery.trim().toLowerCase().replaceAll('ё', 'е');

    final matchingCustom = _customDishes.where((item) {
      if (queryLower.isEmpty) return true;
      final nameLower = item.name.toLowerCase().replaceAll('ё', 'е');
      final brandLower = (item.brand ?? '').toLowerCase().replaceAll('ё', 'е');
      final barcodeLower = (item.barcode ?? '').toLowerCase();
      return nameLower.contains(queryLower) ||
          brandLower.contains(queryLower) ||
          barcodeLower.contains(queryLower);
    }).toList();

    if (queryLower.isNotEmpty) {
      matchingCustom.sort((a, b) {
        final scoreB = OpenFoodFactsService.relevanceScore(b.name, queryLower);
        final scoreA = OpenFoodFactsService.relevanceScore(a.name, queryLower);
        return scoreB.compareTo(scoreA);
      });
    }

    final validApi =
        _apiResults.where((item) => item.caloriesPer100g > 0).toList();

    List<FoodItem> combined;
    switch (_sourceFilter) {
      case SearchSourceFilter.all:
        combined = [...matchingCustom, ...validApi];
        break;
      case SearchSourceFilter.api:
        combined = [...validApi];
        break;
      case SearchSourceFilter.custom:
        combined = [...matchingCustom];
        break;
    }

    if (filterLower.isNotEmpty) {
      combined = combined.where((item) {
        final nameLower = item.name.toLowerCase().replaceAll('ё', 'е');
        final brandLower =
            (item.brand ?? '').toLowerCase().replaceAll('ё', 'е');
        final barcodeLower = (item.barcode ?? '').toLowerCase();
        return nameLower.contains(filterLower) ||
            brandLower.contains(filterLower) ||
            barcodeLower.contains(filterLower);
      }).toList();
    }

    return combined.take(OpenFoodFactsService.maxResultsLimit).toList();
  }

  Future<void> refreshCustomDishes() async {
    try {
      _customDishes = await _repository.getCustomDishes();
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Ошибка обновления своих блюд в поиске', e, st);
    }
  }

  void setSourceFilter(SearchSourceFilter filter) {
    _sourceFilter = filter;
    notifyListeners();
  }

  void setListFilterQuery(String value) {
    _listFilterQuery = value;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (_state == LoadState.loading) return;

    final trimmed = query.trim();
    _lastSearchQuery = trimmed;
    _errorMessage = null;

    await refreshCustomDishes();

    if (trimmed.isEmpty) {
      _apiResults = [];
      _state = LoadState.idle;
      notifyListeners();
      return;
    }

    _state = LoadState.loading;
    notifyListeners();

    try {
      final rawResults = await _repository.searchApi(trimmed);
      _apiResults = rawResults
          .where((item) => item.caloriesPer100g > 0)
          .take(OpenFoodFactsService.maxResultsLimit)
          .toList();
      _state = LoadState.success;
    } on ApiException catch (e) {
      _apiResults = [];
      _errorMessage = e.message;
      _state = LoadState.error;
    } catch (e, st) {
      AppLogger.error('Непредвиденная ошибка поиска в API', e, st);
      _apiResults = [];
      _errorMessage = 'Произошла ошибка при поиске. Попробуйте ещё раз.';
      _state = LoadState.error;
    }

    notifyListeners();
  }

  Future<FoodItem?> searchByBarcode(String barcode) async {
    if (_state == LoadState.loading) return null;

    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await refreshCustomDishes();
      final product = await _repository.getByBarcode(barcode);
      if (product == null) {
        _errorMessage = 'Продукт со штрихкодом $barcode не найден в базе.';
        _state = LoadState.error;
        notifyListeners();
        return null;
      }

      if (!product.isCustom) {
        _apiResults = [product];
      }
      _lastSearchQuery = '';
      _state = LoadState.success;
      notifyListeners();
      return product;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = LoadState.error;
      notifyListeners();
      return null;
    } catch (e, st) {
      AppLogger.error('Ошибка поиска по штрихкоду', e, st);
      _errorMessage = 'Не удалось выполнить поиск по штрихкоду.';
      _state = LoadState.error;
      notifyListeners();
      return null;
    }
  }
}