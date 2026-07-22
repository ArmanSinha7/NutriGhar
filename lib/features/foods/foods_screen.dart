import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/food_search_engine.dart';
import 'food_detail_screen.dart';
import 'custom_food_screen.dart';

class FoodsScreen extends ConsumerStatefulWidget {
  const FoodsScreen({super.key});

  @override
  ConsumerState<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends ConsumerState<FoodsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  FoodFilter _filter = const FoodFilter();
  FoodSortBy _sortBy = FoodSortBy.nameAz;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allFoods = ref.watch(allFoodsProvider);
    final searchEngine = ref.watch(foodSearchEngineProvider);

    List<FoodItem> displayFoods;
    if (_query.isNotEmpty && searchEngine != null) {
      displayFoods = searchEngine
          .search(_query, maxResults: 50)
          .map((r) => r.food)
          .toList();
    } else {
      displayFoods = searchEngine != null
          ? searchEngine.filter(_filter)
          : allFoods;
    }

    if (_query.isEmpty) {
      displayFoods = searchEngine?.sort(displayFoods, _sortBy) ?? displayFoods;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search: chicken curry, चिकन, roti...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('🍲 Food Library'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _query = '';
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
          ),
          if (!_showSearch)
            IconButton(
              onPressed: () => _showSortFilter(context),
              icon: const Icon(Icons.tune_rounded),
            ),
        ],
        bottom: _showSearch ? null : TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Foods'),
            Tab(text: '⭐ Favorites'),
            Tab(text: '🧑‍🍳 Custom'),
          ],
        ),
      ),
      body: _showSearch
          ? _buildFoodList(displayFoods)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFoodList(displayFoods),
                _buildFavorites(),
                _buildCustom(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomFoodScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Custom', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFoodList(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyState(
              emoji: '🔍',
              title: _query.isEmpty ? 'No foods found' : 'No results for "$_query"',
              subtitle: _query.isEmpty
                  ? 'Try searching for something.'
                  : 'Food not found?',
            ),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomFoodScreen(initialName: _query),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Food / Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Active filters row
        if (_filter.hasActiveFilter || _sortBy != FoodSortBy.nameAz)
          _FilterRow(
            filter: _filter,
            sortBy: _sortBy,
            onClear: () => setState(() {
              _filter = const FoodFilter();
              _sortBy = FoodSortBy.nameAz;
            }),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: foods.length,
            itemBuilder: (context, i) {
              final food = foods[i];
              return FoodCard(
                food: food,
                isFavorite: _isFavorite(food.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(food: food),
                  ),
                ),
                onFavoriteTap: () => _toggleFavorite(food.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites() {
    return Consumer(
      builder: (context, ref, _) {
        final activeUser = ref.watch(activeUserProvider);
        return activeUser.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => const SizedBox(),
          data: (user) {
            if (user == null) return const SizedBox();
            final foodRepo = ref.read(foodRepositoryProvider);
            final favorites = foodRepo.getFavorites(user.id);
            if (favorites.isEmpty) {
              return const EmptyState(
                emoji: '⭐',
                title: 'No favorites yet',
                subtitle: 'Tap the heart icon on any food to add it here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: favorites.length,
              itemBuilder: (context, i) {
                final food = favorites[i];
                return FoodCard(
                  food: food,
                  isFavorite: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
                  ),
                  onFavoriteTap: () => _toggleFavorite(food.id),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustom() {
    final allFoods = ref.watch(allFoodsProvider);
    final customFoods = allFoods.where((f) => f.isCustom).toList();
    
    if (customFoods.isEmpty) {
      return EmptyState(
        emoji: '🧑‍🍳',
        title: 'No custom foods',
        subtitle: 'Add your own recipes or foods using the Add Custom button below.',
        actionLabel: 'Create New',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomFoodScreen(),
            ),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: customFoods.length,
      itemBuilder: (context, i) {
        final food = customFoods[i];
        return FoodCard(
          food: food,
          isFavorite: _isFavorite(food.id),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
          ),
          onFavoriteTap: () => _toggleFavorite(food.id),
        );
      },
    );
  }

  bool _isFavorite(String foodId) {
    final user = ref.read(activeUserProvider).value;
    if (user == null) return false;
    final foodRepo = ref.read(foodRepositoryProvider);
    return foodRepo.getFavoriteIds(user.id).contains(foodId);
  }

  Future<void> _toggleFavorite(String foodId) async {
    final user = ref.read(activeUserProvider).value;
    if (user == null) return;
    final foodRepo = ref.read(foodRepositoryProvider);
    await foodRepo.toggleFavorite(user.id, foodId);
    setState(() {});
  }

  void _showSortFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SortFilterSheet(
        currentFilter: _filter,
        currentSort: _sortBy,
        onApply: (filter, sort) {
          setState(() {
            _filter = filter;
            _sortBy = sort;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final FoodFilter filter;
  final FoodSortBy sortBy;
  final VoidCallback onClear;

  const _FilterRow({required this.filter, required this.sortBy, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          if (filter.isVegetarianOnly)
            _Chip(label: '🌱 Veg only'),
          if (filter.mealType != null)
            _Chip(label: filter.mealType!),
          if (sortBy != FoodSortBy.nameAz)
            _Chip(label: 'Sorted'),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}

class _SortFilterSheet extends StatefulWidget {
  final FoodFilter currentFilter;
  final FoodSortBy currentSort;
  final Function(FoodFilter, FoodSortBy) onApply;

  const _SortFilterSheet({
    required this.currentFilter,
    required this.currentSort,
    required this.onApply,
  });

  @override
  State<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<_SortFilterSheet> {
  late FoodFilter _filter;
  late FoodSortBy _sort;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _sort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort & Filter', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          Text('Sort by', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodSortBy.values.map((sortBy) {
              final labels = {
                FoodSortBy.caloriesAsc: '🔥 Lowest Cal',
                FoodSortBy.caloriesDesc: '🔥 Highest Cal',
                FoodSortBy.proteinDesc: '🥩 High Protein',
                FoodSortBy.carbsAsc: '🍚 Low Carbs',
                FoodSortBy.fiberDesc: '🌾 High Fiber',
                FoodSortBy.proteinCalorieRatio: '💪 Best Ratio',
                FoodSortBy.nameAz: '🔤 A–Z',
              };
              final isSelected = _sort == sortBy;
              return GestureDetector(
                onTap: () => setState(() => _sort = sortBy),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[sortBy] ?? sortBy.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('Filters', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('🌱 Vegetarian only'),
                selected: _filter.isVegetarianOnly,
                onSelected: (v) => setState(() => _filter = _filter.copyWith(isVegetarianOnly: v)),
              ),
            ],
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_filter, _sort),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
