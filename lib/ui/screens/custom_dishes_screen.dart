import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/load_state.dart';
import '../../data/models/food_item.dart';
import '../../viewmodels/custom_dishes_viewmodel.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../widgets/add_food_dialog.dart';
import 'barcode_scanner_screen.dart';

class CustomDishesScreen extends StatelessWidget {
  const CustomDishesScreen({super.key});

  Future<void> _openDishForm(
    BuildContext context, {
    FoodItem? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? '');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    final calCtrl = TextEditingController(
      text: existing != null ? existing.caloriesPer100g.toString() : '',
    );
    final protCtrl = TextEditingController(
      text: existing != null ? existing.proteinPer100g.toString() : '',
    );
    final fatCtrl = TextEditingController(
      text: existing != null ? existing.fatPer100g.toString() : '',
    );
    final carbsCtrl = TextEditingController(
      text: existing != null ? existing.carbsPer100g.toString() : '',
    );

    final savedDish = await showDialog<FoodItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Новое блюдо' : 'Редактировать блюдо'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Название блюда *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите название'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Описание / бренд (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: barcodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Штрихкод (необязательно)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Сканировать штрихкод камерой',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scanned = await Navigator.of(ctx).push<String>(
                          MaterialPageRoute(
                            builder: (_) => const BarcodeScannerScreen(),
                          ),
                        );
                        if (scanned != null && scanned.isNotEmpty) {
                          barcodeCtrl.text = scanned;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: calCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Калории на 100 г *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateNumber,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: protCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Б *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: fatCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ж *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: carbsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'У *',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              double parse(String s) => double.parse(s.replaceAll(',', '.'));
              final brand = brandCtrl.text.trim();
              final barcode = barcodeCtrl.text.trim();
              Navigator.of(ctx).pop(
                FoodItem(
                  id: existing?.id,
                  name: nameCtrl.text.trim(),
                  brand: brand.isEmpty ? null : brand,
                  barcode: barcode.isEmpty ? null : barcode,
                  caloriesPer100g: parse(calCtrl.text.trim()),
                  proteinPer100g: parse(protCtrl.text.trim()),
                  fatPer100g: parse(fatCtrl.text.trim()),
                  carbsPer100g: parse(carbsCtrl.text.trim()),
                  isCustom: true,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (savedDish == null || !context.mounted) return;

    final dishesVm = context.read<CustomDishesViewModel>();
    final searchVm = context.read<SearchViewModel>();

    if (existing == null) {
      await dishesVm.addDish(savedDish);
    } else {
      await dishesVm.updateDish(savedDish);
    }
    await searchVm.refreshCustomDishes();
  }

  Future<void> _attachBarcodeQuick(BuildContext context, FoodItem dish) async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (scanned == null || scanned.isEmpty || !context.mounted) return;

    final dishesVm = context.read<CustomDishesViewModel>();
    final searchVm = context.read<SearchViewModel>();

    await dishesVm.updateDish(dish.copyWith(barcode: scanned));
    await searchVm.refreshCustomDishes();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Штрихкод $scanned прикреплён к «${dish.name}»')),
    );
  }

  static String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Заполните';
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null || n < 0 || n > 1000) return '0–1000';
    return null;
  }

  Future<void> _addToDiary(BuildContext context, FoodItem dish) async {
    final diaryVm = context.read<DiaryViewModel>();
    if (diaryVm.meals.isEmpty) {
      await diaryVm.loadDiary();
    }
    if (!context.mounted) return;

    final result = await showDialog<AddFoodResult>(
      context: context,
      builder: (_) => AddFoodDialog(
        food: dish,
        meals: diaryVm.meals,
      ),
    );

    if (result == null || !context.mounted) return;

    await diaryVm.addFoodToMeal(
      mealId: result.mealId,
      food: dish,
      grams: result.grams,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('«${dish.name}» добавлено в дневник')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomDishesViewModel>();
    final dishes = vm.filteredDishes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои блюда'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDishForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Создать блюдо'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: vm.setFilterQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск по моим блюдам...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: vm.state == LoadState.loading && dishes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : dishes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'У вас пока нет своих блюд. Нажмите «Создать блюдо», и оно будет всегда отображаться первым в поиске.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: dishes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final dish = dishes[index];
                          final hasBarcode = dish.barcode != null &&
                              dish.barcode!.trim().isNotEmpty;

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              title: Text(
                                dish.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${dish.caloriesPer100g.round()} ккал на 100 г · '
                                'Б ${dish.proteinPer100g} / Ж ${dish.fatPer100g} / У ${dish.carbsPer100g}'
                                '${hasBarcode ? '\nШтрихкод: ${dish.barcode}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: hasBarcode,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Добавить в дневник',
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _addToDiary(context, dish),
                                  ),
                                  IconButton(
                                    tooltip: hasBarcode
                                        ? 'Перепривязать штрихкод'
                                        : 'Прикрепить штрихкод',
                                    icon: Icon(
                                      Icons.qr_code_scanner,
                                      color: hasBarcode
                                          ? const Color(0xFF1B6E43)
                                          : null,
                                    ),
                                    onPressed: () =>
                                        _attachBarcodeQuick(context, dish),
                                  ),
                                  IconButton(
                                    tooltip: 'Редактировать',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openDishForm(
                                      context,
                                      existing: dish,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Удалить',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      if (dish.id == null) return;
                                      final searchVm =
                                          context.read<SearchViewModel>();
                                      await vm.deleteDish(dish.id!);
                                      await searchVm.refreshCustomDishes();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}