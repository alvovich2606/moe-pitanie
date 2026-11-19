import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_goals.dart';
import '../../viewmodels/goals_viewmodel.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _autoFormKey = GlobalKey<FormState>();
  final _manualFormKey = GlobalKey<FormState>();

  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  GoalType _goalType = GoalType.maintain;

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _calController = TextEditingController();
  final _protController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  bool _initializedFromDb = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calController.dispose();
    _protController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void _syncFields(UserGoals? goals) {
    if (_initializedFromDb || goals == null) return;
    _initializedFromDb = true;
    _gender = goals.gender;
    _activity = goals.activityLevel;
    _goalType = goals.goalType;
    _ageController.text = goals.age.toString();
    _heightController.text = goals.heightCm.toStringAsFixed(0);
    _weightController.text = goals.weightKg.toStringAsFixed(1);
    _calController.text = goals.targetCalories.toString();
    _protController.text = goals.targetProtein.toString();
    _fatController.text = goals.targetFat.toString();
    _carbsController.text = goals.targetCarbs.toString();
  }

  Future<void> _onCalculate() async {
    if (_autoFormKey.currentState?.validate() != true) return;

    final age = int.parse(_ageController.text.trim());
    final height = double.parse(_heightController.text.replaceAll(',', '.'));
    final weight = double.parse(_weightController.text.replaceAll(',', '.'));

    final vm = context.read<GoalsViewModel>();
    final ok = await vm.calculateAndSave(
      gender: _gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      activityLevel: _activity,
      goalType: _goalType,
    );

    if (!mounted || !ok) return;

    final updated = vm.goals!;
    _calController.text = updated.targetCalories.toString();
    _protController.text = updated.targetProtein.toString();
    _fatController.text = updated.targetFat.toString();
    _carbsController.text = updated.targetCarbs.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Норма КБЖУ рассчитана и сохранена')),
    );
  }

  Future<void> _onSaveManual() async {
    if (_manualFormKey.currentState?.validate() != true) return;

    final cal = int.parse(_calController.text.trim());
    final prot = int.parse(_protController.text.trim());
    final fat = int.parse(_fatController.text.trim());
    final carbs = int.parse(_carbsController.text.trim());

    final ok = await context.read<GoalsViewModel>().saveManual(
          calories: cal,
          protein: prot,
          fat: fat,
          carbs: carbs,
        );

    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ручная норма КБЖУ сохранена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GoalsViewModel>();
    _syncFields(vm.goals);

    final modeText = vm.goals == null
        ? 'Норма ещё не задана'
        : (vm.goals!.isManual
            ? 'Текущий режим: ручная настройка'
            : 'Текущий режим: автоматический расчёт');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Норма КБЖУ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Автоматический расчёт по формуле Миффлина — Сан Жеора или ручная настройка дневных целей',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _autoFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Автоматический расчёт по параметрам',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(value: Gender.male, label: Text('Мужской')),
                        ButtonSegment(
                          value: Gender.female,
                          label: Text('Женский'),
                        ),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (s) =>
                          setState(() => _gender = s.first),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Возраст',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              if (n == null || n < 10 || n > 120) {
                                return '10–120';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Рост (см)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              if (n == null || n < 100 || n > 250) {
                                return '100–250';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Вес (кг)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              if (n == null || n < 30 || n > 300) {
                                return '30–300';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ActivityLevel>(
                      initialValue: _activity,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Уровень активности',
                        border: OutlineInputBorder(),
                      ),
                      items: ActivityLevel.values
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _activity = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    ...GoalType.values.map((type) {
                      final selected = _goalType == type;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _goalType = type),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEAF5EE)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF1B6E43)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? const Color(0xFF1B6E43)
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _onCalculate,
                        child: const Text('Пересчитать и применить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _manualFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ручная настройка нормы КБЖУ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _calController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Калории в день (ккал)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 500 || n > 10000) {
                          return 'Введите от 500 до 10000';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _protController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Белки (г)',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateMacro,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Жиры (г)',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateMacro,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Углеводы (г)',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateMacro,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _onSaveManual,
                        child: const Text('Сохранить вручную'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateMacro(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 0 || n > 1000) {
      return '0–1000';
    }
    return null;
  }
}