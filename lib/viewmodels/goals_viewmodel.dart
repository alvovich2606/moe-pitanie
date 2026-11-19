import 'package:flutter/foundation.dart';

import '../core/app_logger.dart';
import '../core/load_state.dart';
import '../data/models/user_goals.dart';
import '../data/repositories/goals_repository.dart';

class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository _repository;

  LoadState _state = LoadState.idle;
  UserGoals? _goals;
  String? _errorMessage;

  GoalsViewModel(this._repository);

  LoadState get state => _state;
  UserGoals? get goals => _goals;
  String? get errorMessage => _errorMessage;
  bool get hasGoals => _goals != null;

  Future<void> loadGoals() async {
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _repository.getGoals();
      _state = LoadState.success;
    } catch (e, st) {
      AppLogger.error('Ошибка загрузки нормы КБЖУ', e, st);
      _errorMessage = 'Не удалось загрузить норму КБЖУ.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> calculateAndSave({
    required Gender gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required GoalType goalType,
  }) async {
    try {
      final calculated = UserGoals.calculate(
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        activityLevel: activityLevel,
        goalType: goalType,
      );
      await _repository.saveGoals(calculated);
      _goals = calculated;
      _state = LoadState.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('Ошибка расчёта и сохранения нормы', e, st);
      _errorMessage = 'Не удалось сохранить расчёт.';
      _state = LoadState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveManual({
    required int calories,
    required int protein,
    required int fat,
    required int carbs,
  }) async {
    try {
      final base = _goals ??
          UserGoals.calculate(
            gender: Gender.male,
            age: 20,
            heightCm: 175,
            weightKg: 70,
            activityLevel: ActivityLevel.moderate,
            goalType: GoalType.maintain,
          );

      final updated = base.copyWith(
        isManual: true,
        targetCalories: calories,
        targetProtein: protein,
        targetFat: fat,
        targetCarbs: carbs,
      );

      await _repository.saveGoals(updated);
      _goals = updated;
      _state = LoadState.success;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.error('Ошибка ручного сохранения нормы', e, st);
      _errorMessage = 'Не удалось сохранить ручную норму.';
      _state = LoadState.error;
      notifyListeners();
      return false;
    }
  }
}