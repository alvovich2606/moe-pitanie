import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/load_state.dart';
import '../../data/models/food_item.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../widgets/add_food_dialog.dart';
import 'barcode_scanner_screen.dart';

class SearchScreen extends StatefulWidget {
  final int? preselectedMealId;

  const SearchScreen({
    super.key,
    this.preselectedMealId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _filterController = TextEditingController();

  static const List<String> _quickQueries = [
    'Творог',
    'Гречка',
    'Куриная грудка',
    'Йогурт',
    'Овсянка',
    'Банан',
    'Молоко',
    'Сыр',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    FocusScope.of(context).unfocus();
    _searchController.text = query;
    await context.read<SearchViewModel>().search(query);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || barcode == null || barcode.isEmpty) return;

    final product =
        await context.read<SearchViewModel>().searchByBarcode(barcode);
    if (!mounted) return;

    if (product != null) {
      await _selectFood(product);
    }
  }

  Future<void> _selectFood(FoodItem food) async {
    final diaryVm = context.read<DiaryViewModel>();
    if (diaryVm.meals.isEmpty) {
      await diaryVm.loadDiary();
    }
    if (!mounted) return;

    final result = await showDialog<AddFoodResult>(
      context: context,
      builder: (_) => AddFoodDialog(
        food: food,
        meals: diaryVm.meals,
        initialMealId: widget.preselectedMealId,
      ),
    );

    if (result == null || !mounted) return;

    await diaryVm.addFoodToMeal(
      mealId: result.mealId,
      food: food,
      grams: result.grams,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('«${food.name}» добавлено в дневник')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    final items = vm.results;
    final isLoading = vm.state == LoadState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск еды'),
        actions: [
          IconButton(
            tooltip: 'Сканировать штрихкод',
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _performSearch,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Введите название продукта...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => _performSearch(_searchController.text),
                  child: const Text('Найти'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickQueries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final chipText = _quickQueries[index];
                return ActionChip(
                  label: Text(chipText),
                  onPressed: isLoading ? null : () => _performSearch(chipText),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<SearchSourceFilter>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
                segments: [
                  const ButtonSegment(
                    value: SearchSourceFilter.all,
                    label: Text(
                      'Все',
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const ButtonSegment(
                    value: SearchSourceFilter.api,
                    label: Text(
                      'Open Food Facts',
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  ButtonSegment(
                    value: SearchSourceFilter.custom,
                    label: Text(
                      'Мои (${vm.customDishesCount})',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ],
                selected: {vm.sourceFilter},
                onSelectionChanged: (selection) {
                  vm.setSourceFilter(selection.first);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _filterController,
              onChanged: vm.setListFilterQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.tune),
                hintText: 'Фильтр по текущему списку...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (isLoading) const LinearProgressIndicator(),
          if (vm.state == LoadState.error && vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Найдено продуктов: ${items.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const Text(
                  'Значения указаны на 100 г',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        vm.lastSearchQuery.isEmpty
                            ? 'Введите название продукта и нажмите «Найти» или отсканируйте штрихкод. Ваши блюда всегда отображаются первыми.'
                            : 'По запросу «${vm.lastSearchQuery}» ничего не найдено.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final food = items[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${food.isCustom ? "Моё блюдо" : (food.brand ?? "Open Food Facts")} · '
                            'Б ${food.proteinPer100g} / Ж ${food.fatPer100g} / У ${food.carbsPer100g}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${food.caloriesPer100g.round()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Text(
                                    'ккал',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed: () => _selectFood(food),
                                child: const Text('Выбрать'),
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