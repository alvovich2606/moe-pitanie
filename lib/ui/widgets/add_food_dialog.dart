import 'package:flutter/material.dart';

import '../../data/models/food_item.dart';
import '../../data/models/meal.dart';

class AddFoodResult {
  final int mealId;
  final double grams;

  const AddFoodResult({
    required this.mealId,
    required this.grams,
  });
}

class AddFoodDialog extends StatefulWidget {
  final FoodItem food;
  final List<Meal> meals;
  final int? initialMealId;

  const AddFoodDialog({
    super.key,
    required this.food,
    required this.meals,
    this.initialMealId,
  });

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gramsController = TextEditingController(text: '100');
  late int _selectedMealId;

  @override
  void initState() {
    super.initState();
    _selectedMealId = widget.initialMealId ??
        (widget.meals.isNotEmpty ? widget.meals.first.id! : 0);
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  double get _currentGrams {
    final parsed =
        double.tryParse(_gramsController.text.replaceAll(',', '.')) ?? 0;
    return parsed > 0 ? parsed : 0;
  }

  @override
  Widget build(BuildContext context) {
    final factor = _currentGrams / 100.0;
    final kcal = (widget.food.caloriesPer100g * factor).round();
    final protein = (widget.food.proteinPer100g * factor).toStringAsFixed(1);
    final fat = (widget.food.fatPer100g * factor).toStringAsFixed(1);
    final carbs = (widget.food.carbsPer100g * factor).toStringAsFixed(1);

    return AlertDialog(
      title: Text(
        widget.food.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'На 100 г: ${widget.food.caloriesPer100g.round()} ккал · '
                'Б ${widget.food.proteinPer100g} · '
                'Ж ${widget.food.fatPer100g} · '
                'У ${widget.food.carbsPer100g}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (widget.meals.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedMealId,
                  decoration: const InputDecoration(
                    labelText: 'Приём пищи',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.meals
                      .map(
                        (m) => DropdownMenuItem<int>(
                          value: m.id,
                          child: Text(m.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMealId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _gramsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Вес порции (г)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите вес в граммах';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0 || parsed > 5000) {
                    return 'Введите число от 1 до 5000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Итого: $kcal ккал · Б $protein · Ж $fat · У $carbs',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B6E43),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.of(context).pop(
              AddFoodResult(
                mealId: _selectedMealId,
                grams: _currentGrams,
              ),
            );
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}