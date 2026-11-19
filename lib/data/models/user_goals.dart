enum Gender {
  male,
  female,
}

enum ActivityLevel {
  minimal(1.2, 'Минимальная — сидячий образ жизни'),
  low(1.375, 'Низкая — 1–3 лёгкие тренировки в неделю'),
  moderate(1.55, 'Средняя — 3–5 умеренных тренировок в неделю'),
  high(1.725, 'Высокая — 6–7 интенсивных тренировок в неделю'),
  veryHigh(1.9, 'Очень высокая — физическая работа или 2 тренировки в день');

  final double multiplier;
  final String label;

  const ActivityLevel(this.multiplier, this.label);
}

enum GoalType {
  lose(0.85, 'Похудение', 'Мягкий дефицит -15% от нормы'),
  maintain(1.0, 'Поддержание веса', 'Сбалансированный рацион'),
  gain(1.15, 'Набор массы', 'Профицит +15% для роста мышц');

  final double multiplier;
  final String title;
  final String subtitle;

  const GoalType(this.multiplier, this.title, this.subtitle);
}

class UserGoals {
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final bool isManual;
  final int targetCalories;
  final int targetProtein;
  final int targetFat;
  final int targetCarbs;

  const UserGoals({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goalType,
    required this.isManual,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetFat,
    required this.targetCarbs,
  });

  /// Расчёт КБЖУ по формуле Миффлина — Сан Жеора
  static UserGoals calculate({
    required Gender gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required GoalType goalType,
  }) {
    final baseBmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final bmr = gender == Gender.male ? baseBmr + 5 : baseBmr - 161;
    final rawCalories = bmr * activityLevel.multiplier * goalType.multiplier;
    final targetCalories = rawCalories.round().clamp(1000, 10000);

    // Баланс БЖУ: 25% белки, 30% жиры, 45% углеводы
    final targetProtein = ((targetCalories * 0.25) / 4).round();
    final targetFat = ((targetCalories * 0.30) / 9).round();
    final targetCarbs = ((targetCalories * 0.45) / 4).round();

    return UserGoals(
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goalType: goalType,
      isManual: false,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetFat: targetFat,
      targetCarbs: targetCarbs,
    );
  }

  UserGoals copyWith({
    Gender? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    bool? isManual,
    int? targetCalories,
    int? targetProtein,
    int? targetFat,
    int? targetCarbs,
  }) {
    return UserGoals(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      isManual: isManual ?? this.isManual,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetFat: targetFat ?? this.targetFat,
      targetCarbs: targetCarbs ?? this.targetCarbs,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': 1,
      'gender': gender.name,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel.name,
      'goal_type': goalType.name,
      'is_manual': isManual ? 1 : 0,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_fat': targetFat,
      'target_carbs': targetCarbs,
    };
  }

  factory UserGoals.fromDbMap(Map<String, dynamic> map) {
    return UserGoals(
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.male,
      ),
      age: map['age'] as int,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == map['activity_level'],
        orElse: () => ActivityLevel.moderate,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == map['goal_type'],
        orElse: () => GoalType.maintain,
      ),
      isManual: (map['is_manual'] as int) == 1,
      targetCalories: map['target_calories'] as int,
      targetProtein: map['target_protein'] as int,
      targetFat: map['target_fat'] as int,
      targetCarbs: map['target_carbs'] as int,
    );
  }
}