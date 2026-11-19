class MealEntry {
  final int? id;
  final int mealId;
  final String foodName;
  final double grams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;

  const MealEntry({
    this.id,
    required this.mealId,
    required this.foodName,
    required this.grams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
  });

  double get totalCalories => caloriesPer100g * grams / 100.0;
  double get totalProtein => proteinPer100g * grams / 100.0;
  double get totalFat => fatPer100g * grams / 100.0;
  double get totalCarbs => carbsPer100g * grams / 100.0;

  MealEntry copyWith({
    int? id,
    int? mealId,
    String? foodName,
    double? grams,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? carbsPer100g,
  }) {
    return MealEntry(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'meal_id': mealId,
      'food_name': foodName,
      'grams': grams,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'fat_per_100g': fatPer100g,
      'carbs_per_100g': carbsPer100g,
    };
  }

  factory MealEntry.fromDbMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      mealId: map['meal_id'] as int,
      foodName: map['food_name'] as String,
      grams: (map['grams'] as num).toDouble(),
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num).toDouble(),
    );
  }
}