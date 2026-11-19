import 'package:flutter_test/flutter_test.dart';
import 'package:kbzhu_diary/data/models/food_item.dart';
import 'package:kbzhu_diary/data/models/meal.dart';
import 'package:kbzhu_diary/data/models/meal_entry.dart';
import 'package:kbzhu_diary/data/models/user_goals.dart';

void main() {
  group('Unit-тесты бизнес-логики КБЖУ', () {
    test('1. Расчёт нормы по Миффлину — Сан Жеора (мужчина, поддержание)', () {
      final goals = UserGoals.calculate(
        gender: Gender.male,
        age: 19,
        heightCm: 183,
        weightKg: 84,
        activityLevel: ActivityLevel.moderate,
        goalType: GoalType.maintain,
      );

      expect(goals.targetCalories, 2935);
      expect(goals.targetProtein, 183);
      expect(goals.targetFat, 98);
      expect(goals.targetCarbs, 330);
      expect(goals.isManual, false);
    });

    test('2. Расчёт нормы с дефицитом для похудения (-15%)', () {
      final maintain = UserGoals.calculate(
        gender: Gender.female,
        age: 25,
        heightCm: 165,
        weightKg: 60,
        activityLevel: ActivityLevel.low,
        goalType: GoalType.maintain,
      );
      final lose = UserGoals.calculate(
        gender: Gender.female,
        age: 25,
        heightCm: 165,
        weightKg: 60,
        activityLevel: ActivityLevel.low,
        goalType: GoalType.lose,
      );

      expect(lose.targetCalories, lessThan(maintain.targetCalories));
      expect(lose.targetCalories, (maintain.targetCalories * 0.85).round());
    });

    test('3. Пересчёт КБЖУ порции MealEntry по граммовке', () {
      const entry = MealEntry(
        mealId: 1,
        foodName: 'Куриная грудка',
        grams: 150,
        caloriesPer100g: 110,
        proteinPer100g: 23.6,
        fatPer100g: 1.9,
        carbsPer100g: 0.4,
      );

      expect(entry.totalCalories, closeTo(165.0, 0.01));
      expect(entry.totalProtein, closeTo(35.4, 0.01));
      expect(entry.totalFat, closeTo(2.85, 0.01));
      expect(entry.totalCarbs, closeTo(0.6, 0.01));
    });

    test('4. Суммирование КБЖУ по всем продуктам внутри приёма пищи Meal', () {
      const meal = Meal(
        id: 1,
        date: '2026-11-19',
        name: 'Завтрак',
        sortOrder: 0,
        entries: [
          MealEntry(
            mealId: 1,
            foodName: 'Овсянка',
            grams: 100,
            caloriesPer100g: 350,
            proteinPer100g: 12,
            fatPer100g: 6,
            carbsPer100g: 60,
          ),
          MealEntry(
            mealId: 1,
            foodName: 'Банан',
            grams: 150,
            caloriesPer100g: 90,
            proteinPer100g: 1.5,
            fatPer100g: 0.2,
            carbsPer100g: 22,
          ),
        ],
      );

      expect(meal.totalCalories, closeTo(485.0, 0.01));
      expect(meal.totalProtein, closeTo(14.25, 0.01));
      expect(meal.totalFat, closeTo(6.3, 0.01));
      expect(meal.totalCarbs, closeTo(93.0, 0.01));
    });

    test('5. Парсинг FoodItem из JSON Open Food Facts с конвертацией кДж в ккал', () {
      final json = <String, dynamic>{
        'code': '4607027760014',
        'product_name_ru': 'Творог 5%',
        'brands': 'Простоквашино',
        'nutriments': {
          'energy-kj_100g': 506.264,
          'proteins_100g': 16.0,
          'fat_100g': 5.0,
          'carbohydrates_100g': 3.0,
        },
      };

      final item = FoodItem.fromOpenFoodFactsJson(json);

      expect(item.name, 'Творог 5%');
      expect(item.brand, 'Простоквашино');
      expect(item.barcode, '4607027760014');
      expect(item.caloriesPer100g, closeTo(121.0, 0.2));
      expect(item.proteinPer100g, 16.0);
      expect(item.isCustom, false);
    });
  });
}