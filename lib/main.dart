import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database_helper.dart';
import 'data/repositories/diary_repository.dart';
import 'data/repositories/food_repository.dart';
import 'data/repositories/goals_repository.dart';
import 'data/services/open_food_facts_service.dart';
import 'ui/screens/custom_dishes_screen.dart';
import 'ui/screens/diary_screen.dart';
import 'ui/screens/goals_screen.dart';
import 'ui/screens/search_screen.dart';
import 'viewmodels/custom_dishes_viewmodel.dart';
import 'viewmodels/diary_viewmodel.dart';
import 'viewmodels/goals_viewmodel.dart';
import 'viewmodels/search_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final apiService = OpenFoodFactsService();

  final goalsRepo = SqliteGoalsRepository(dbHelper);
  final diaryRepo = SqliteDiaryRepository(dbHelper);
  final foodRepo = AppFoodRepository(dbHelper, apiService);

  runApp(
    KbzhuApp(
      goalsRepository: goalsRepo,
      diaryRepository: diaryRepo,
      foodRepository: foodRepo,
    ),
  );
}

class KbzhuApp extends StatelessWidget {
  final GoalsRepository goalsRepository;
  final DiaryRepository diaryRepository;
  final FoodRepository foodRepository;

  const KbzhuApp({
    super.key,
    required this.goalsRepository,
    required this.diaryRepository,
    required this.foodRepository,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B6E43);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(goalsRepository)..loadGoals(),
        ),
        ChangeNotifierProvider(
          create: (_) => DiaryViewModel(diaryRepository)..loadDiary(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomDishesViewModel(foodRepository)..loadDishes(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(foodRepository)..refreshCustomDishes(),
        ),
      ],
      child: MaterialApp(
        title: 'Мое питание',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen,
            primary: primaryGreen,
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F8F5),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int? _targetMealId;

  void _openSearchForMeal(int mealId) {
    setState(() {
      _targetMealId = mealId;
      _currentIndex = 1;
    });
  }

  void _openGoalsTab() {
    setState(() {
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DiaryScreen(
        onAddFoodToMeal: _openSearchForMeal,
        onOpenGoals: _openGoalsTab,
      ),
      SearchScreen(preselectedMealId: _targetMealId),
      const GoalsScreen(),
      const CustomDishesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            if (index != 1) {
              _targetMealId = null;
            }
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Дневник',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Норма',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Мои блюда',
          ),
        ],
      ),
    );
  }
}