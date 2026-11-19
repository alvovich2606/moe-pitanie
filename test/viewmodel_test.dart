import 'package:flutter_test/flutter_test.dart';
import 'package:kbzhu_diary/core/load_state.dart';
import 'package:kbzhu_diary/data/models/food_item.dart';
import 'package:kbzhu_diary/data/repositories/food_repository.dart';
import 'package:kbzhu_diary/data/services/open_food_facts_service.dart';
import 'package:kbzhu_diary/viewmodels/search_viewmodel.dart';

class FakeFoodRepository implements FoodRepository {
  List<FoodItem> customDishes = [];
  List<FoodItem> apiResults = [];
  bool shouldThrowApiError = false;

  @override
  Future<List<FoodItem>> getCustomDishes() async => List.of(customDishes);

  @override
  Future<int> addCustomDish(FoodItem dish) async {
    customDishes.add(dish);
    return customDishes.length;
  }

  @override
  Future<void> updateCustomDish(FoodItem dish) async {}

  @override
  Future<void> deleteCustomDish(int id) async {
    customDishes.removeWhere((d) => d.id == id);
  }

  @override
  Future<List<FoodItem>> searchApi(String query) async {
    if (shouldThrowApiError) {
      throw const ApiException('Нет подключения к интернету.');
    }
    return List.of(apiResults);
  }

  @override
  Future<FoodItem?> getByBarcode(String barcode) async {
    for (final dish in customDishes) {
      if (dish.barcode == barcode) return dish;
    }
    return null;
  }
}

void main() {
  group('SearchViewModel с фейковым репозиторием', () {
    test('Свои блюда всегда отображаются первыми перед результатами API', () async {
      final fakeRepo = FakeFoodRepository()
        ..customDishes = const [
          FoodItem(
            id: 1,
            name: 'Сырники из творога 5%',
            caloriesPer100g: 184,
            proteinPer100g: 14.2,
            fatPer100g: 6.4,
            carbsPer100g: 17.5,
            isCustom: true,
          ),
        ]
        ..apiResults = const [
          FoodItem(
            name: 'Творог классический 5%',
            caloriesPer100g: 121,
            proteinPer100g: 16.0,
            fatPer100g: 5.0,
            carbsPer100g: 3.0,
            isCustom: false,
          ),
        ];

      final vm = SearchViewModel(fakeRepo);
      await vm.search('творог');

      expect(vm.state, LoadState.success);
      expect(vm.results.length, 2);
      expect(vm.results.first.isCustom, true);
      expect(vm.results.first.name, 'Сырники из творога 5%');
      expect(vm.results.last.isCustom, false);
    });

    test('Обработка ошибки сети: state = error и понятное сообщение', () async {
      final fakeRepo = FakeFoodRepository()..shouldThrowApiError = true;
      final vm = SearchViewModel(fakeRepo);

      await vm.search('гречка');

      expect(vm.state, LoadState.error);
      expect(vm.errorMessage, 'Нет подключения к интернету.');
    });
  });
}