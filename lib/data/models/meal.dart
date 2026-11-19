import 'meal_entry.dart';

class Meal {
  final int? id;
  final String date; // формат YYYY-MM-DD
  final String name;
  final int sortOrder;
  final List<MealEntry> entries;

  const Meal({
    this.id,
    required this.date,
    required this.name,
    required this.sortOrder,
    this.entries = const [],
  });

  double get totalCalories =>
      entries.fold(0.0, (sum, item) => sum + item.totalCalories);

  double get totalProtein =>
      entries.fold(0.0, (sum, item) => sum + item.totalProtein);

  double get totalFat =>
      entries.fold(0.0, (sum, item) => sum + item.totalFat);

  double get totalCarbs =>
      entries.fold(0.0, (sum, item) => sum + item.totalCarbs);

  Meal copyWith({
    int? id,
    String? date,
    String? name,
    int? sortOrder,
    List<MealEntry>? entries,
  }) {
    return Meal(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory Meal.fromDbMap(
    Map<String, dynamic> map, {
    List<MealEntry> entries = const [],
  }) {
    return Meal(
      id: map['id'] as int?,
      date: map['date'] as String,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int,
      entries: entries,
    );
  }
}