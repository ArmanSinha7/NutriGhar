import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/food_search_engine.dart';
import '../../core/services/nutrition_calculator.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  MealType _selectedMealType = MealType.lunch;
  final _searchController = TextEditingController();
  final _quickInputController = TextEditingController();
  String _searchQuery = '';
  final List<_PendingItem> _pendingItems = [];
  bool _isQuickMode = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Default to current meal time
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = MealType.breakfast;
    } else if (hour < 16) {
      _selectedMealType = MealType.lunch;
    } else if (hour < 18) {
      _selectedMealType = MealType.snack;
    } else {
      _selectedMealType = MealType.dinner;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchEngine = ref.watch(foodSearchEngineProvider);

    List<SearchResult> searchResults = [];
    if (_searchQuery.trim().isNotEmpty && searchEngine != null) {
      searchResults = searchEngine.search(_searchQuery, maxResults: 30);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('🍽️ Log Food'),
        actions: [
          TextButton.icon(
            onPressed: _pendingItems.isEmpty ? null : _saveMeal,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text('Save (${_pendingItems.length})'),
            style: TextButton.styleFrom(
              foregroundColor: _pendingItems.isEmpty ? AppColors.textTertiary : AppColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meal type selector
          _MealTypeSelector(
            selected: _selectedMealType,
            onChanged: (t) => setState(() => _selectedMealType = t),
          ),

          // Input mode toggle
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isQuickMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isQuickMode ? AppColors.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Center(
                        child: Text(
                          '🔍 Search Foods',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: !_isQuickMode ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isQuickMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isQuickMode ? AppColors.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Center(
                        child: Text(
                          '⚡ Quick Input',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _isQuickMode ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isQuickMode ? _buildQuickInput() : _buildSearchMode(searchResults),
          ),

          // Pending items
          if (_pendingItems.isNotEmpty) _PendingItemsPanel(
            items: _pendingItems,
            onRemove: (i) => setState(() => _pendingItems.removeAt(i)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchMode(List<SearchResult> results) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search: dal makhani, roti, chicken...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        if (_searchQuery.isEmpty) ...[
          // Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick picks:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                _QuickPickRow(onTap: (query) {
                  setState(() {
                    _searchQuery = query;
                    _searchController.text = query;
                  });
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Expanded(
          child: results.isEmpty && _searchQuery.isNotEmpty
              ? const EmptyState(emoji: '🔍', title: 'No results', subtitle: 'Try Hindi or English names.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final food = results[i].food;
                    return FoodCard(
                      food: food,
                      showNutrition: true,
                      onTap: () => _showPortionPicker(food),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickInput() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type your meal in natural language:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'e.g. "2 roti aur aadha plate sabji" or "chicken curry + rice"',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quickInputController,
            decoration: const InputDecoration(
              hintText: '2 roti, dal, rice...',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _parseQuickInput(),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Parse & Add'),
            ),
          ),
          const SizedBox(height: 20),
          Text('🚀 Example phrases:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...const [
            '3 roti + dal + sabji',
            'aadha plate rice aur chicken curry',
            'poha with chai',
            '2 idli + sambar',
            'paneer tikka 150g',
          ].map((example) => GestureDetector(
                onTap: () {
                  _quickInputController.text = example;
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('"$example"', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showPortionPicker(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortionSelectorBottomSheet(
        food: food,
        onConfirm: (portion, qty) {
          final calc = NutritionCalculator();
          final nutrition = calc.calculateForPortion(food: food, portion: portion, quantity: qty);
          setState(() {
            _pendingItems.add(_PendingItem(
              food: food,
              portion: portion,
              quantity: qty,
              nutrition: nutrition,
            ));
          });
        },
      ),
    );
  }

  Future<void> _parseQuickInput() async {
    final input = _quickInputController.text.trim();
    if (input.isEmpty) return;

    final searchEngine = ref.read(foodSearchEngineProvider);
    if (searchEngine == null) return;

    final parser = FoodParser(searchEngine);
    final parsed = parser.parse(input);

    final calc = NutritionCalculator();
    int added = 0;

    for (final entry in parsed) {
      if (entry.food != null && entry.matchedPortion != null) {
        final nutrition = calc.calculateForPortion(
          food: entry.food!,
          portion: entry.matchedPortion!,
          quantity: entry.quantity,
        );
        _pendingItems.add(_PendingItem(
          food: entry.food!,
          portion: entry.matchedPortion!,
          quantity: entry.quantity,
          nutrition: nutrition,
        ));
        added++;
      }
    }

    setState(() {});
    _quickInputController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added > 0
            ? '$added item${added > 1 ? 's' : ''} added! Tap Save to log.'
            : 'Could not parse that. Try simpler phrasing.'),
      ));
    }
  }

  Future<void> _saveMeal() async {
    if (_pendingItems.isEmpty) return;

    final user = ref.read(activeUserProvider).value;
    if (user == null) return;

    final items = _pendingItems.map((pending) {
      return MealItem(
        id: _uuid.v4(),
        foodId: pending.food.id,
        food: pending.food,
        portionName: pending.portion.name,
        quantity: pending.quantity,
        nutrition: pending.nutrition,
      );
    }).toList();

    final meal = Meal(
      id: _uuid.v4(),
      userProfileId: user.id,
      date: DateTime.now(),
      mealType: _selectedMealType,
      items: items,
    );

    final mealRepo = ref.read(mealRepositoryProvider);
    await mealRepo.saveMeal(meal);

    ref.invalidate(todayMealsProvider);
    ref.invalidate(todayNutritionProvider);

    setState(() => _pendingItems.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Meal logged successfully! 🎉'),
      ));
    }
  }
}

class _MealTypeSelector extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  const _MealTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: MealType.values.map((type) {
          final isSelected = selected == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _mealColor(type).withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? _mealColor(type) : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_mealEmoji(type), style: const TextStyle(fontSize: 18)),
                    Text(
                      _mealName(type),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? _mealColor(type) : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _mealColor(MealType t) {
    switch (t) {
      case MealType.breakfast: return AppColors.breakfastColor;
      case MealType.lunch: return AppColors.lunchColor;
      case MealType.snack: return AppColors.snackColor;
      case MealType.dinner: return AppColors.dinnerColor;
    }
  }

  String _mealEmoji(MealType t) {
    switch (t) {
      case MealType.breakfast: return '🍳';
      case MealType.lunch: return '🍛';
      case MealType.snack: return '🥗';
      case MealType.dinner: return '🌙';
    }
  }

  String _mealName(MealType t) {
    switch (t) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.snack: return 'Snack';
      case MealType.dinner: return 'Dinner';
    }
  }
}

class _QuickPickRow extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _QuickPickRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const picks = ['roti', 'rice', 'dal', 'sabji', 'chicken', 'paneer', 'egg', 'chai'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: picks.map((pick) => GestureDetector(
        onTap: () => onTap(pick),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(pick, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      )).toList(),
    );
  }
}

class _PendingItemsPanel extends StatelessWidget {
  final List<_PendingItem> items;
  final ValueChanged<int> onRemove;

  const _PendingItemsPanel({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    NutritionRange total = NutritionRange.zero;
    for (final item in items) {
      total = total + item.nutrition;
    }

    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${items.length} item${items.length > 1 ? 's' : ''} pending',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '~${total.caloriesMin.round()}–${total.caloriesMax.round()} kcal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.calorieColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.food.name} × ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onRemove(i),
                        child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                      ),
                    ],
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

class _PendingItem {
  final FoodItem food;
  final PortionSize portion;
  final double quantity;
  final NutritionRange nutrition;

  const _PendingItem({
    required this.food,
    required this.portion,
    required this.quantity,
    required this.nutrition,
  });
}
