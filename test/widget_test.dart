import 'package:flutter_test/flutter_test.dart';
import 'package:kbzhu_diary/data/models/food_item.dart';
import 'package:kbzhu_diary/data/models/meal.dart';
import 'package:kbzhu_diary/data/models/meal_entry.dart';
import 'package:kbzhu_diary/data/models/user_goals.dart';
import 'package:kbzhu_diary/data/repositories/diary_repository.dart';
import 'package:kbzhu_diary/data/repositories/food_repository.dart';
import 'package:kbzhu_diary/data/repositories/goals_repository.dart';
import 'package:kbzhu_diary/main.dart';

class _FakeGoalsRepo implements GoalsRepository {
  UserGoals? _goals;

  @override
  Future<UserGoals?> getGoals() async => _goals;

  @override
  Future<void> saveGoals(UserGoals goals) async {
    _goals = goals;
  }
}

class _FakeDiaryRepo implements DiaryRepository {
  @override
  Future<List<Meal>> getMealsForDate(String date) async => const [
        Meal(id: 1, date: '2026-11-19', name: 'Завтрак', sortOrder: 0),
        Meal(id: 2, date: '2026-11-19', name: 'Обед', sortOrder: 1),
      ];

  @override
  Future<int> addMeal(String date, String name) async => 3;

  @override
  Future<void> renameMeal(int mealId, String newName) async {}

  @override
  Future<void> deleteMeal(int mealId) async {}

  @override
  Future<int> addEntry(MealEntry entry) async => 1;

  @override
  Future<void> updateEntryGrams(int entryId, double grams) async {}

  @override
  Future<void> deleteEntry(int entryId) async {}
}

class _FakeFoodRepo implements FoodRepository {
  @override
  Future<List<FoodItem>> getCustomDishes() async => [];

  @override
  Future<int> addCustomDish(FoodItem dish) async => 1;

  @override
  Future<void> updateCustomDish(FoodItem dish) async {}

  @override
  Future<void> deleteCustomDish(int id) async {}

  @override
  Future<List<FoodItem>> searchApi(String query) async => [];

  @override
  Future<FoodItem?> getByBarcode(String barcode) async => null;
}

void main() {
  testWidgets('Отображаются 4 вкладки навигации и экран Дневник', (tester) async {
    await tester.pumpWidget(
      KbzhuApp(
        goalsRepository: _FakeGoalsRepo(),
        diaryRepository: _FakeDiaryRepo(),
        foodRepository: _FakeFoodRepo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Дневник'), findsWidgets);
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Норма'), findsOneWidget);
    expect(find.text('Мои блюда'), findsOneWidget);
    expect(find.text('Завтрак'), findsOneWidget);
  });
}