import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/nutrition_calculator.dart';
import '../../core/services/recommendation_engine.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);
    return activeUser.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading profile'))),
      data: (user) {
        if (user == null) return const SizedBox();
        return _ProgressContent(user: user);
      },
    );
  }
}

class _ProgressContent extends ConsumerStatefulWidget {
  final UserProfile user;
  const _ProgressContent({required this.user});

  @override
  ConsumerState<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends ConsumerState<_ProgressContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('📊 Progress'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '⚖️ Weight'),
            Tab(text: '🍽️ Nutrition'),
            Tab(text: '🏃 Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeightTab(user: widget.user),
          _NutritionTab(user: widget.user),
          _ActivityTab(user: widget.user),
        ],
      ),
    );
  }
}

// ─── Weight Tab ─────────────────────────────────────────────────────────────

class _WeightTab extends ConsumerStatefulWidget {
  final UserProfile user;
  const _WeightTab({required this.user});

  @override
  ConsumerState<_WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<_WeightTab> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weightEntries = ref.watch(weightEntriesProvider(widget.user.id));

    return weightEntries.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Error loading data')),
      data: (entries) {
        final analytics = AnalyticsEngine();
        final trend = analytics.analyzeWeightTrend(entries);
        final bmiCalc = BMICalculator();

        // Calculate BMI from latest weight
        double? bmi;
        BMICategory? bmiCategory;
        if (entries.isNotEmpty && widget.user.heightCm != null) {
          bmi = bmiCalc.calculate(
            weightKg: entries.first.weightKg,
            heightCm: widget.user.heightCm!,
          );
          bmiCategory = bmiCalc.categorize(bmi);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Log weight
            _LogWeightCard(
              controller: _weightController,
              noteController: _noteController,
              onLog: () => _logWeight(entries.isNotEmpty ? entries.first.weightKg : null),
            ),

            const SizedBox(height: 16),

            // Trend card
            if (entries.length >= 2)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📈 Weight Trend', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(trend.message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _trendColor(trend.direction),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // BMI
            if (bmi != null && bmiCategory != null)
              BMIGauge(bmi: bmi, category: bmiCategory),

            const SizedBox(height: 16),

            // Weight chart
            if (entries.length >= 2) ...[
              Text('Weight history', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: _WeightChart(entries: entries.take(14).toList().reversed.toList()),
              ),
              const SizedBox(height: 16),
            ],

            // Weight entries list
            Text('History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ...entries.take(10).map((e) => _WeightEntryCard(
              entry: e,
              previousWeight: entries.indexOf(e) + 1 < entries.length
                  ? entries[entries.indexOf(e) + 1].weightKg
                  : null,
            )),

            if (entries.isEmpty)
              const EmptyState(
                emoji: '⚖️',
                title: 'No weight entries yet',
                subtitle: 'Log your weight above to start tracking your progress.',
              ),

            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Future<void> _logWeight(double? previousWeight) async {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight.')),
      );
      return;
    }

    final entry = WeightEntry(
      id: _uuid.v4(),
      userProfileId: widget.user.id,
      date: DateTime.now(),
      weightKg: value,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    final weightRepo = ref.read(weightRepositoryProvider);
    await weightRepo.addEntry(entry);
    ref.invalidate(weightEntriesProvider);

    _weightController.clear();
    _noteController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight logged! ✅')),
      );
    }
  }

  Color _trendColor(TrendDirection d) {
    switch (d) {
      case TrendDirection.down:
        return AppColors.success;
      case TrendDirection.up:
        return AppColors.error;
      case TrendDirection.stable:
        return AppColors.textSecondary;
    }
  }
}

class _LogWeightCard extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController noteController;
  final VoidCallback onLog;

  const _LogWeightCard({
    required this.controller,
    required this.noteController,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log today\'s weight', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. After workout',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Weight'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightEntryCard extends StatelessWidget {
  final WeightEntry entry;
  final double? previousWeight;

  const _WeightEntryCard({required this.entry, this.previousWeight});

  @override
  Widget build(BuildContext context) {
    double? change;
    if (previousWeight != null) change = entry.weightKg - previousWeight!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_monthName(entry.date.month)} ${entry.date.day}, ${entry.date.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (entry.note != null)
                Text(entry.note!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                )),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.weightKg.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (change != null)
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: change < 0 ? AppColors.success : AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox();

    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weightKg);
    }).toList();

    final minY = entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.02)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nutrition Tab ──────────────────────────────────────────────────────────

class _NutritionTab extends ConsumerWidget {
  final UserProfile user;
  const _NutritionTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayNutrition = ref.watch(todayNutritionProvider(user.id));
    final userGoal = ref.watch(userGoalProvider(user.id));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Today\'s Nutrition', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        todayNutrition.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => const Text('Error'),
          data: (summary) => userGoal.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const Text('Error'),
            data: (goal) {
              if (goal == null) {
                return const EmptyState(
                  emoji: '🎯',
                  title: 'No goals set',
                  subtitle: 'Set your goals to see nutrition progress.',
                );
              }
              return _NutritionBreakdown(summary: summary, goal: goal);
            },
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _NutritionBreakdown extends StatelessWidget {
  final DailyNutritionSummary summary;
  final UserGoal goal;

  const _NutritionBreakdown({required this.summary, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Macro pie chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: summary.totalCalories == 0
              ? const Center(child: EmptyState(emoji: '🍽️', title: 'Log some meals to see your breakdown', subtitle: ''))
              : Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(value: summary.totalProtein, color: AppColors.proteinColor, title: 'P', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            PieChartSectionData(value: summary.totalCarbs, color: AppColors.carbColor, title: 'C', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            PieChartSectionData(value: summary.totalFat, color: AppColors.fatColor, title: 'F', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(color: AppColors.proteinColor, label: 'Protein', value: '${summary.totalProtein.toStringAsFixed(0)}g'),
                          _LegendItem(color: AppColors.carbColor, label: 'Carbs', value: '${summary.totalCarbs.toStringAsFixed(0)}g'),
                          _LegendItem(color: AppColors.fatColor, label: 'Fat', value: '${summary.totalFat.toStringAsFixed(0)}g'),
                          _LegendItem(color: AppColors.fiberColor, label: 'Fiber', value: '${summary.totalFiber.toStringAsFixed(0)}g'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Detailed progress bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              MacroProgressBar(
                label: 'Calories',
                emoji: '🔥',
                consumed: summary.totalCalories,
                target: goal.dailyCalorieTarget.toDouble(),
                color: AppColors.calorieColor,
                unit: 'kcal',
              ),
              const SizedBox(height: 14),
              MacroProgressBar(
                label: 'Protein',
                emoji: '🥩',
                consumed: summary.totalProtein,
                target: goal.dailyProteinTargetG,
                color: AppColors.proteinColor,
              ),
              const SizedBox(height: 14),
              MacroProgressBar(
                label: 'Carbs',
                emoji: '🍚',
                consumed: summary.totalCarbs,
                target: goal.dailyCarbTargetG,
                color: AppColors.carbColor,
              ),
              const SizedBox(height: 14),
              MacroProgressBar(
                label: 'Fat',
                emoji: '🥑',
                consumed: summary.totalFat,
                target: goal.dailyFatTargetG,
                color: AppColors.fatColor,
              ),
              const SizedBox(height: 14),
              MacroProgressBar(
                label: 'Fiber',
                emoji: '🌾',
                consumed: summary.totalFiber,
                target: goal.dailyFiberTargetG,
                color: AppColors.fiberColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Activity Tab ────────────────────────────────────────────────────────────

class _ActivityTab extends ConsumerStatefulWidget {
  final UserProfile user;
  const _ActivityTab({required this.user});

  @override
  ConsumerState<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends ConsumerState<_ActivityTab> {
  ActivityType _activityType = ActivityType.walking;
  ActivityIntensity _intensity = ActivityIntensity.moderate;
  int _duration = 30;
  final _noteController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityEntries = ref.watch(activityEntriesProvider(widget.user.id));
    final activityCalc = ref.read(activityCalculatorProvider);
    final weight = widget.user.weightKg ?? 70.0;

    final estimatedBurn = activityCalc.estimate(
      activity: _activityType,
      durationMinutes: _duration,
      weightKg: weight,
      intensity: _intensity,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Log activity
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log activity', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              DropdownButtonFormField<ActivityType>(
                value: _activityType,
                decoration: const InputDecoration(labelText: 'Activity type'),
                items: ActivityType.values.map((t) => DropdownMenuItem(
                  value: t, child: Text('${_activityEmoji(t)} ${_activityName(t)}', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _activityType = v); },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Duration: $_duration min', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: _duration.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _duration = v.round()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Estimated burn preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.calorieColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated burn', style: Theme.of(context).textTheme.labelMedium),
                        Text('~${estimatedBurn.round()} kcal',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.calorieColor, fontWeight: FontWeight.w800,
                          )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logActivity,
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Log Activity'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Activity entries
        activityEntries.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => const Text('Error'),
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyState(
                emoji: '🏃',
                title: 'No activities logged yet',
                subtitle: 'Log your first workout to start tracking.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 10),
                ...entries.take(10).map((e) => _ActivityEntryCard(entry: e)),
              ],
            );
          },
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _logActivity() async {
    final activityCalc = ref.read(activityCalculatorProvider);
    final weight = widget.user.weightKg ?? 70.0;
    final calories = activityCalc.estimate(
      activity: _activityType,
      durationMinutes: _duration,
      weightKg: weight,
      intensity: _intensity,
    );

    final entry = ActivityEntry(
      id: _uuid.v4(),
      userProfileId: widget.user.id,
      date: DateTime.now(),
      activityType: _activityType,
      durationMinutes: _duration,
      intensity: _intensity,
      caloriesBurned: calories,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    final activityRepo = ref.read(activityRepositoryProvider);
    await activityRepo.addEntry(entry);
    ref.invalidate(activityEntriesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity logged! ~${calories.round()} kcal burned 💪')),
      );
    }
  }

  String _activityEmoji(ActivityType t) {
    const map = {
      ActivityType.walking: '🚶',
      ActivityType.running: '🏃',
      ActivityType.cycling: '🚴',
      ActivityType.swimming: '🏊',
      ActivityType.strengthTraining: '💪',
      ActivityType.yoga: '🧘',
      ActivityType.householdWork: '🧹',
      ActivityType.other: '🤸',
    };
    return map[t] ?? '🏋️';
  }

  String _activityName(ActivityType t) {
    const map = {
      ActivityType.walking: 'Walking',
      ActivityType.running: 'Running',
      ActivityType.cycling: 'Cycling',
      ActivityType.swimming: 'Swimming',
      ActivityType.strengthTraining: 'Strength Training',
      ActivityType.yoga: 'Yoga',
      ActivityType.householdWork: 'Household Work',
      ActivityType.other: 'Other',
    };
    return map[t] ?? 'Activity';
  }
}

class _ActivityEntryCard extends StatelessWidget {
  final ActivityEntry entry;

  const _ActivityEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Text(_emoji(entry.activityType), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name(entry.activityType), style: Theme.of(context).textTheme.titleSmall),
                Text('${entry.durationMinutes} min • ${entry.date.day}/${entry.date.month}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '🔥 ~${entry.caloriesBurned.round()} kcal',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.calorieColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _emoji(ActivityType t) {
    const map = {ActivityType.walking: '🚶', ActivityType.running: '🏃', ActivityType.cycling: '🚴', ActivityType.swimming: '🏊', ActivityType.strengthTraining: '💪', ActivityType.yoga: '🧘', ActivityType.householdWork: '🧹', ActivityType.other: '🤸'};
    return map[t] ?? '🏋️';
  }

  String _name(ActivityType t) {
    const map = {ActivityType.walking: 'Walking', ActivityType.running: 'Running', ActivityType.cycling: 'Cycling', ActivityType.swimming: 'Swimming', ActivityType.strengthTraining: 'Strength Training', ActivityType.yoga: 'Yoga', ActivityType.householdWork: 'Household Work', ActivityType.other: 'Other'};
    return map[t] ?? 'Activity';
  }
}
