import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/recommendation_engine.dart';
import '../fact_corner/fact_corner_screen.dart';
import '../family/family_screen.dart';
import '../meal_prep/meal_prep_screen.dart';
import '../habits/habit_tracker_screen.dart';
import 'widgets/streaks_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);

    return activeUser.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Something went wrong. Try restarting.')),
      ),
      data: (user) {
        if (user == null) return const SizedBox();
        return _HomeContent(user: user);
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final UserProfile user;

  const _HomeContent({required this.user});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayNutrition = ref.watch(todayNutritionProvider(user.id));
    final todayMeals = ref.watch(todayMealsProvider(user.id));
    final userGoal = ref.watch(userGoalProvider(user.id));
    final weightEntries = ref.watch(weightEntriesProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundWarm,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🥘', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                const Text('NutriGhar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyScreen()),
                ),
                icon: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
                tooltip: 'Family',
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FactCornerScreen()),
                ),
                icon: const Icon(Icons.local_fire_department_rounded, color: AppColors.calorieColor),
                tooltip: 'Fact Corner',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, ${user.name} 👋',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // Weight badge
                    weightEntries.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (entries) {
                        if (entries.isEmpty) return const SizedBox();
                        final latest = entries.first;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            children: [
                              const Text('⚖️', style: TextStyle(fontSize: 16)),
                              Text(
                                '${latest.weightKg.toStringAsFixed(1)} kg',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const StreaksWidget(),


                const SizedBox(height: AppSpacing.xl),

                // Nutrition overview
                userGoal.when(
                  loading: () => const _NutritionSkeleton(),
                  error: (_, __) => const SizedBox(),
                  data: (goal) {
                    return todayNutrition.when(
                      loading: () => const _NutritionSkeleton(),
                      error: (_, __) => const SizedBox(),
                      data: (summary) => _NutritionOverview(
                        summary: summary,
                        goal: goal,
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Meal Prep Banner
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealPrepScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Text('🍱', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan Your Week',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Generate meal prep plans & grocery lists',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Habit Tracker Banner
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HabitTrackerScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Habit Tracker',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Build consistency and track your daily habits',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Today's meals
                SectionHeader(
                  title: '🍽️ Today\'s Meals',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('View all'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                todayMeals.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox(),
                  data: (meals) {
                    if (meals.isEmpty) {
                      return EmptyState(
                        emoji: '🍽️',
                        title: 'No meals logged yet',
                        subtitle: 'Start with your first meal today.',
                        actionLabel: '+ Log Food',
                        onAction: () {},
                      );
                    }
                    return Column(
                      children: meals.map((meal) => _MealSummaryCard(meal: meal)).toList(),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Insights
                userGoal.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (goal) => todayNutrition.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (summary) {
                      if (goal == null || summary.mealCount == 0) return const SizedBox();
                      final analytics = ref.read(analyticsEngineProvider);
                      final insights = analytics.generateDailyInsights(
                        goal: goal,
                        summary: summary,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: '💡 Today\'s Insights'),
                          const SizedBox(height: AppSpacing.md),
                          ...insights.map((insight) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InsightCard(insight: insight),
                              )),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      );
                    },
                  ),
                ),

                // Fact of the day card
                _FactOfTheDayCard(onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FactCornerScreen()));
                }),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Analytics engine provider (add to providers.dart if not present)
final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) => AnalyticsEngine());

class _NutritionOverview extends StatelessWidget {
  final DailyNutritionSummary summary;
  final UserGoal? goal;

  const _NutritionOverview({required this.summary, required this.goal});

  @override
  Widget build(BuildContext context) {
    final calTarget = goal?.dailyCalorieTarget.toDouble() ?? 2000;
    final proteinTarget = goal?.dailyProteinTargetG ?? 120;
    final carbTarget = goal?.dailyCarbTargetG ?? 250;
    final fatTarget = goal?.dailyFatTargetG ?? 65;
    final fiberTarget = goal?.dailyFiberTargetG ?? 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔥 Today\'s Nutrition', style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      '${summary.mealCount} meal${summary.mealCount != 1 ? 's' : ''} logged',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CalorieRingIndicator(
                consumed: summary.totalCalories,
                target: calTarget,
                size: 100,
              ),
            ],
          ),
          const SizedBox(height: 20),
          MacroProgressBar(
            label: 'Protein',
            emoji: '🥩',
            consumed: summary.totalProtein,
            target: proteinTarget,
            color: AppColors.proteinColor,
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Carbohydrates',
            emoji: '🍚',
            consumed: summary.totalCarbs,
            target: carbTarget,
            color: AppColors.carbColor,
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Fat',
            emoji: '🥑',
            consumed: summary.totalFat,
            target: fatTarget,
            color: AppColors.fatColor,
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Fiber',
            emoji: '🌾',
            consumed: summary.totalFiber,
            target: fiberTarget,
            color: AppColors.fiberColor,
          ),
        ],
      ),
    );
  }
}

class _NutritionSkeleton extends StatelessWidget {
  const _NutritionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}

class _MealSummaryCard extends StatelessWidget {
  final Meal meal;

  const _MealSummaryCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final total = meal.totalNutrition;
    final mealEmoji = _mealEmoji(meal.mealType);
    final mealName = _mealName(meal.mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _mealColor(meal.mealType).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$mealEmoji $mealName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _mealColor(meal.mealType),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '~${total.caloriesMin.round()}–${total.caloriesMax.round()} kcal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.calorieColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (meal.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meal.items.map((i) => i.food?.name ?? 'Unknown').join(', '),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _MiniMacro(emoji: '🥩', value: '${total.protein.toStringAsFixed(0)}g protein'),
              const SizedBox(width: 8),
              _MiniMacro(emoji: '🍚', value: '${total.carbs.toStringAsFixed(0)}g carbs'),
            ],
          ),
        ],
      ),
    );
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

  Color _mealColor(MealType t) {
    switch (t) {
      case MealType.breakfast: return AppColors.breakfastColor;
      case MealType.lunch: return AppColors.lunchColor;
      case MealType.snack: return AppColors.snackColor;
      case MealType.dinner: return AppColors.dinnerColor;
    }
  }
}

class _MiniMacro extends StatelessWidget {
  final String emoji;
  final String value;

  const _MiniMacro({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _FactOfTheDayCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FactOfTheDayCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final facts = [
      '💡 Protein provides ~4 kcal per gram. Great sources: dal, paneer, chicken, eggs.',
      '💡 Your body burns calories even while sleeping — that\'s your BMR at work!',
      '💡 Homemade dal-roti is one of the most nutritious and balanced Indian meals.',
      '💡 Reducing oil by just 1 tablespoon per day saves ~120 kcal.',
      '💡 A katori of moong dal has ~12g protein — as much as 2 boiled eggs!',
    ];
    final fact = facts[DateTime.now().day % facts.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fact of the Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fact,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}
