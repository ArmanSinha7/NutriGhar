import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/di/providers.dart';

class MealPrepScreen extends ConsumerStatefulWidget {
  const MealPrepScreen({super.key});

  @override
  ConsumerState<MealPrepScreen> createState() => _MealPrepScreenState();
}

class _MealPrepScreenState extends ConsumerState<MealPrepScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDays = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('🍱 Meal Prep'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Meal Plan'),
            Tab(text: 'Grocery List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealPlanTab(),
          _buildGroceryListTab(),
        ],
      ),
    );
  }

  Widget _buildMealPlanTab() {
    final currentPrepAsync = ref.watch(currentMealPrepProvider);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Plan for: '),
              DropdownButton<int>(
                value: _selectedDays,
                items: [3, 5, 7].map((days) => DropdownMenuItem(
                  value: days,
                  child: Text('$days Days'),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDays = v);
                },
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton(
                onPressed: _generatePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate'),
              )
            ],
          ),
        ),
        Expanded(
          child: currentPrepAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (prep) {
              if (prep == null) {
                return const Center(child: Text('No plan generated yet.'));
              }
              return _buildPrepDays(prep);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrepDays(MealPrep prep) {
    final itemsAsync = ref.watch(mealPrepItemsProvider(prep.id));
    final allFoods = ref.watch(allFoodsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Error loading items')),
      data: (items) {
        // Group by day
        final Map<int, List<MealPrepItem>> dayMap = {};
        for (var item in items) {
          dayMap.putIfAbsent(item.day, () => []).add(item);
        }

        return ListView.builder(
          itemCount: prep.days,
          itemBuilder: (context, index) {
            final day = index + 1;
            final dayItems = dayMap[day] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: ExpansionTile(
                title: Text('Day $day'),
                children: dayItems.map((item) {
                  final food = allFoods.where((f) => f.id == item.foodId).firstOrNull;
                  final title = '${item.mealType.name.toUpperCase()}: ${food?.name ?? 'Unknown'}';
                  final subtitle = '${item.quantity} ${item.portionName}';
                  return ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                  );
                }).toList(),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildGroceryListTab() {
    final currentPrepAsync = ref.watch(currentMealPrepProvider);
    final allFoods = ref.watch(allFoodsProvider);

    return currentPrepAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Error')),
      data: (prep) {
        if (prep == null) {
          return const Center(child: Text('Generate a plan first.'));
        }

        final itemsAsync = ref.watch(mealPrepItemsProvider(prep.id));
        return itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Center(child: Text('Error loading items')),
          data: (items) {
            // Aggregate ingredients
            final Map<String, double> groceryList = {};
            for (var item in items) {
              final food = allFoods.where((f) => f.id == item.foodId).firstOrNull;
              if (food != null) {
                final key = '${food.name} (${item.portionName})';
                groceryList[key] = (groceryList[key] ?? 0) + item.quantity;
              }
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Combined Ingredients for your plan:'),
                ),
                ...groceryList.entries.map((e) => CheckboxListTile(
                  value: false,
                  onChanged: (v) {},
                  title: Text(e.key),
                  subtitle: Text('${e.value}'),
                )),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generatePlan() async {
    final service = ref.read(mealPrepServiceProvider);
    await service.generatePlan(_selectedDays);
    ref.invalidate(currentMealPrepProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal plan generated!')),
      );
    }
  }
}
