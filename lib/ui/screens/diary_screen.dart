import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/load_state.dart';
import '../../data/models/meal.dart';
import '../../data/models/meal_entry.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../viewmodels/goals_viewmodel.dart';

class DiaryScreen extends StatelessWidget {
  final void Function(int mealId) onAddFoodToMeal;
  final VoidCallback onOpenGoals;

  const DiaryScreen({
    super.key,
    required this.onAddFoodToMeal,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    final diaryVm = context.watch<DiaryViewModel>();
    final goalsVm = context.watch<GoalsViewModel>();
    final goals = goalsVm.goals;

    final dateLabel = DateFormat('dd.MM.yyyy').format(diaryVm.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник'),
        actions: [
          IconButton(
            tooltip: 'Предыдущий день',
            onPressed: diaryVm.previousDay,
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: diaryVm.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                await diaryVm.changeDate(picked);
              }
            },
            child: Text(
              dateLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Следующий день',
            onPressed: diaryVm.nextDay,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryCard(
            eatenCalories: diaryVm.totalCalories,
            eatenProtein: diaryVm.totalProtein,
            eatenFat: diaryVm.totalFat,
            eatenCarbs: diaryVm.totalCarbs,
            targetCalories: goals?.targetCalories,
            targetProtein: goals?.targetProtein,
            targetFat: goals?.targetFat,
            targetCarbs: goals?.targetCarbs,
            onOpenGoals: onOpenGoals,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Приёмы пищи',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => _showAddMealDialog(context, diaryVm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Новый приём пищи'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildMealsList(context, diaryVm),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(BuildContext context, DiaryViewModel diaryVm) {
    if (diaryVm.state == LoadState.loading && diaryVm.meals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (diaryVm.state == LoadState.error && diaryVm.meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(diaryVm.errorMessage ?? 'Ошибка загрузки дневника'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: diaryVm.loadDiary,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (diaryVm.meals.isEmpty) {
      return const Center(
        child: Text('Нет приёмов пищи. Нажмите «+ Новый приём пищи».'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: diaryVm.meals.length,
      itemBuilder: (context, index) {
        final meal = diaryVm.meals[index];
        return _MealCard(
          meal: meal,
          onAddFood: () {
            if (meal.id != null) {
              onAddFoodToMeal(meal.id!);
            }
          },
          onRenameMeal: () => _showRenameMealDialog(context, diaryVm, meal),
          onDeleteMeal: () => _confirmDeleteMeal(context, diaryVm, meal),
          onEditEntry: (entry) =>
              _showEditGramsDialog(context, diaryVm, entry),
          onDeleteEntry: (entry) {
            if (entry.id != null) {
              diaryVm.deleteEntry(entry.id!);
            }
          },
        );
      },
    );
  }

  Future<void> _showAddMealDialog(
    BuildContext context,
    DiaryViewModel vm,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый приём пищи'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Название (например, Полдник)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Введите название';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await vm.addMeal(name);
    }
  }

  Future<void> _showRenameMealDialog(
    BuildContext context,
    DiaryViewModel vm,
    Meal meal,
  ) async {
    if (meal.id == null) return;
    final controller = TextEditingController(text: meal.name);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переименовать приём пищи'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Новое название',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Введите название';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await vm.renameMeal(meal.id!, newName);
    }
  }

  Future<void> _confirmDeleteMeal(
    BuildContext context,
    DiaryViewModel vm,
    Meal meal,
  ) async {
    if (meal.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить «${meal.name}»?'),
        content: const Text(
          'Все продукты, добавленные в этот приём пищи, тоже будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vm.deleteMeal(meal.id!);
    }
  }

  Future<void> _showEditGramsDialog(
    BuildContext context,
    DiaryViewModel vm,
    MealEntry entry,
  ) async {
    if (entry.id == null) return;
    final controller =
        TextEditingController(text: entry.grams.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    final grams = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry.foodName),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Вес порции (г)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Введите вес';
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0 || parsed > 5000) {
                return 'Введите число от 1 до 5000';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final parsed = double.parse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.of(ctx).pop(parsed);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (grams != null) {
      await vm.updateEntryGrams(entry.id!, grams);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final double eatenCalories;
  final double eatenProtein;
  final double eatenFat;
  final double eatenCarbs;
  final int? targetCalories;
  final int? targetProtein;
  final int? targetFat;
  final int? targetCarbs;
  final VoidCallback onOpenGoals;

  const _SummaryCard({
    required this.eatenCalories,
    required this.eatenProtein,
    required this.eatenFat,
    required this.eatenCarbs,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetFat,
    required this.targetCarbs,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoals = targetCalories != null && targetCalories! > 0;
    final progress = hasGoals
        ? (eatenCalories / targetCalories!).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasGoals
                      ? '${eatenCalories.round()} /$targetCalories ккал'
                      : '${eatenCalories.round()} ккал',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!hasGoals)
                  TextButton(
                    onPressed: onOpenGoals,
                    child: const Text('Задать норму'),
                  ),
              ],
            ),
            if (hasGoals) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEAF5EE),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MacroChip(
                  label: 'Белки',
                  eaten: eatenProtein,
                  target: targetProtein,
                  color: const Color(0xFF2563EB),
                ),
                _MacroChip(
                  label: 'Жиры',
                  eaten: eatenFat,
                  target: targetFat,
                  color: const Color(0xFFB45309),
                ),
                _MacroChip(
                  label: 'Углеводы',
                  eaten: eatenCarbs,
                  target: targetCarbs,
                  color: const Color(0xFF1B6E43),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double eaten;
  final int? target;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.eaten,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = target != null
        ? '${eaten.toStringAsFixed(1)} /$target г'
        : '${eaten.toStringAsFixed(1)} г';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onAddFood;
  final VoidCallback onRenameMeal;
  final VoidCallback onDeleteMeal;
  final void Function(MealEntry entry) onEditEntry;
  final void Function(MealEntry entry) onDeleteEntry;

  const _MealCard({
    required this.meal,
    required this.onAddFood,
    required this.onRenameMeal,
    required this.onDeleteMeal,
    required this.onEditEntry,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meal.totalCalories.round()} ккал · '
                        'Б ${meal.totalProtein.toStringAsFixed(1)} · '
                        'Ж ${meal.totalFat.toStringAsFixed(1)} · '
                        'У ${meal.totalCarbs.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddFood,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') onRenameMeal();
                    if (value == 'delete') onDeleteMeal();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text('Переименовать'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (meal.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Пока пусто. Нажмите «Добавить», чтобы найти продукт или выбрать своё блюдо.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meal.entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = meal.entries[index];
                return ListTile(
                  title: Text(
                    entry.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${entry.grams.toStringAsFixed(0)} г · '
                    'Б ${entry.totalProtein.toStringAsFixed(1)} · '
                    'Ж ${entry.totalFat.toStringAsFixed(1)} · '
                    'У ${entry.totalCarbs.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry.totalCalories.round()} ккал',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Изменить вес',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => onEditEntry(entry),
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => onDeleteEntry(entry),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}