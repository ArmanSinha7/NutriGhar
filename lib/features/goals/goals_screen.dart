import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/nutrition_calculator.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);
    return activeUser.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error'))),
      data: (user) {
        if (user == null) return const SizedBox();
        return _GoalsContent(user: user);
      },
    );
  }
}

class _GoalsContent extends ConsumerStatefulWidget {
  final UserProfile user;
  const _GoalsContent({required this.user});

  @override
  ConsumerState<_GoalsContent> createState() => _GoalsContentState();
}

class _GoalsContentState extends ConsumerState<_GoalsContent> {
  bool _isEditing = false;

  // Edit state
  WeightGoal? _editGoal;
  ActivityLevel? _editActivity;
  double? _editTargetWeight;
  int? _editCalorieTarget;

  @override
  Widget build(BuildContext context) {
    final userGoal = ref.watch(userGoalProvider(widget.user.id));

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('🎯 Goals & Recommendations'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: userGoal.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Error')),
        data: (goal) {
          if (goal == null) {
            return const EmptyState(
              emoji: '🎯',
              title: 'No goals set',
              subtitle: 'Complete onboarding to set your nutrition goals.',
            );
          }

          if (_isEditing) {
            return _buildEditForm(goal);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Goal summary card
              _GoalSummaryCard(goal: goal, user: widget.user),
              const SizedBox(height: 16),

              // BMR / TDEE breakdown
              _CalorieBreakdownCard(user: widget.user, goal: goal),
              const SizedBox(height: 16),

              // Macro targets
              _MacroTargetCard(goal: goal),
              const SizedBox(height: 16),

              // Recommendations section
              _RecommendationsSection(user: widget.user, goal: goal),
              const SizedBox(height: 16),

              // Quick tips
              _TipsCard(goal: goal),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditForm(UserGoal currentGoal) {
    _editGoal ??= currentGoal.goalType;
    _editActivity ??= widget.user.activityLevel;
    _editTargetWeight ??= currentGoal.targetWeightKg;
    _editCalorieTarget ??= currentGoal.dailyCalorieTarget;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Edit Your Goal', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        
        DropdownButtonFormField<WeightGoal>(
          value: _editGoal,
          decoration: const InputDecoration(labelText: 'Primary Goal', border: OutlineInputBorder()),
          items: WeightGoal.values.map((g) {
            return DropdownMenuItem(value: g, child: Text(g.name.toUpperCase()));
          }).toList(),
          onChanged: (v) => setState(() => _editGoal = v),
        ),
        const SizedBox(height: AppSpacing.md),
        
        DropdownButtonFormField<ActivityLevel>(
          value: _editActivity,
          decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
          items: ActivityLevel.values.map((a) {
            return DropdownMenuItem(value: a, child: Text(a.name));
          }).toList(),
          onChanged: (v) => setState(() => _editActivity = v),
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (_editGoal != WeightGoal.maintain)
          TextFormField(
            initialValue: _editTargetWeight?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Target Weight (kg)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            onChanged: (v) => _editTargetWeight = double.tryParse(v),
          ),
        const SizedBox(height: AppSpacing.md),

        TextFormField(
          initialValue: _editCalorieTarget?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Manual Calorie Override (Optional)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          onChanged: (v) => _editCalorieTarget = int.tryParse(v),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          onPressed: () => _saveGoal(currentGoal),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveGoal(UserGoal currentGoal) async {
    final updatedUser = widget.user.copyWith(
      activityLevel: _editActivity,
      goal: _editGoal,
    );

    // Recalculate targets based on new user parameters
    final bmr = BMRCalculator().calculate(
      weightKg: updatedUser.weightKg ?? 70,
      heightCm: updatedUser.heightCm ?? 170,
      age: updatedUser.age ?? 30,
      gender: updatedUser.gender ?? Gender.other,
    );
    final tdee = BMRCalculator().estimateTDEE(bmr, updatedUser.activityLevel);
    
    int newCalorieTarget = BMRCalculator().calculateDailyTarget(tdee, updatedUser.goal);
    if (_editCalorieTarget != null) {
      newCalorieTarget = _editCalorieTarget!;
    }
    
    final proteinTarget = BMRCalculator().calculateProteinTarget(updatedUser.weightKg ?? 70, updatedUser.goal);
    
    // Macro splits: 1g protein = 4 cals, 1g carb = 4 cals, 1g fat = 9 cals
    final proteinCals = proteinTarget * 4;
    final remainingCals = (newCalorieTarget - proteinCals).clamp(0, double.infinity).toDouble();
    final carbTarget = (remainingCals * 0.5) / 4;
    final fatTarget = (remainingCals * 0.5) / 9;

    final updatedGoal = currentGoal.copyWith(
      goalType: _editGoal,
      targetWeightKg: _editTargetWeight,
      dailyCalorieTarget: newCalorieTarget,
      dailyProteinTargetG: proteinTarget,
      dailyCarbTargetG: carbTarget,
      dailyFatTargetG: fatTarget,
    );

    final userRepo = ref.read(userProfileRepositoryProvider);
    final goalRepo = ref.read(goalRepositoryProvider);

    await userRepo.saveProfile(updatedUser);
    await goalRepo.saveGoal(updatedGoal);
    
    ref.invalidate(activeUserProvider);
    ref.invalidate(userGoalProvider(widget.user.id));
    
    setState(() => _isEditing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal updated!')));
    }
  }
}

class _GoalSummaryCard extends StatelessWidget {
  final UserGoal goal;
  final UserProfile user;

  const _GoalSummaryCard({required this.goal, required this.user});

  @override
  Widget build(BuildContext context) {
    final goalEmoji = goal.goalType == WeightGoal.lose ? '⬇️' : goal.goalType == WeightGoal.gain ? '⬆️' : '⚖️';
    final goalLabel = goal.goalType == WeightGoal.lose ? 'Lose Weight' : goal.goalType == WeightGoal.gain ? 'Gain Weight' : 'Maintain Weight';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goalEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Goal', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(goalLabel, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _GoalStat(label: 'Daily Calories', value: '${goal.dailyCalorieTarget} kcal'),
              _GoalStat(label: 'Protein', value: '${goal.dailyProteinTargetG.round()}g'),
              if (goal.targetWeightKg != null)
                _GoalStat(label: 'Target', value: '${goal.targetWeightKg!.toStringAsFixed(1)} kg'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Started ${_formatDate(goal.startDate)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _GoalStat extends StatelessWidget {
  final String label;
  final String value;

  const _GoalStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CalorieBreakdownCard extends StatelessWidget {
  final UserProfile user;
  final UserGoal goal;

  const _CalorieBreakdownCard({required this.user, required this.goal});

  @override
  Widget build(BuildContext context) {
    if (user.weightKg == null || user.heightCm == null || user.age == null || user.gender == null) {
      return const SizedBox();
    }

    final bmrCalc = BMRCalculator();
    final bmr = bmrCalc.calculate(
      weightKg: user.weightKg!,
      heightCm: user.heightCm!,
      age: user.age!,
      gender: user.gender!,
    );
    final tdee = bmrCalc.estimateTDEE(bmr, user.activityLevel);

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
          Text('📊 Calorie Breakdown', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _BreakdownRow('🛋️ Basal Metabolic Rate (BMR)', '~${bmr.round()} kcal/day', 'Calories burned at rest'),
          const Divider(height: 16),
          _BreakdownRow('⚡ Activity Multiplier', _activityLabel(user.activityLevel), ''),
          const Divider(height: 16),
          _BreakdownRow('🏃 Total Daily Expenditure (TDEE)', '~${tdee.round()} kcal/day', ''),
          const Divider(height: 16),
          _BreakdownRow(
            '🎯 Your Daily Target',
            '${goal.dailyCalorieTarget} kcal/day',
            goal.goalType == WeightGoal.lose ? 'TDEE − 400 kcal deficit'
              : goal.goalType == WeightGoal.gain ? 'TDEE + 300 kcal surplus'
              : 'Maintenance',
            isTarget: true,
          ),
          const SizedBox(height: 8),
          const Text(
            '* These are estimates based on standard formulas. Individual results vary.',
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary: return '1.2× (Sedentary)';
      case ActivityLevel.lightlyActive: return '1.375× (Lightly active)';
      case ActivityLevel.moderatelyActive: return '1.55× (Moderately active)';
      case ActivityLevel.veryActive: return '1.725× (Very active)';
      case ActivityLevel.extraActive: return '1.9× (Extra active)';
    }
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool isTarget;

  const _BreakdownRow(this.label, this.value, this.note, {this.isTarget = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: isTarget ? FontWeight.w700 : FontWeight.w500,
              )),
              if (note.isNotEmpty)
                Text(note, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isTarget ? 16 : 14,
            color: isTarget ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MacroTargetCard extends StatelessWidget {
  final UserGoal goal;

  const _MacroTargetCard({required this.goal});

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
          Text('🥗 Daily Macro Targets', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroTarget(emoji: '🥩', label: 'Protein', value: '${goal.dailyProteinTargetG.round()}g', color: AppColors.proteinColor),
              _MacroTarget(emoji: '🍚', label: 'Carbs', value: '${goal.dailyCarbTargetG.round()}g', color: AppColors.carbColor),
              _MacroTarget(emoji: '🥑', label: 'Fat', value: '${goal.dailyFatTargetG.round()}g', color: AppColors.fatColor),
              _MacroTarget(emoji: '🌾', label: 'Fiber', value: '${goal.dailyFiberTargetG.round()}g', color: AppColors.fiberColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTarget extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _MacroTarget({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsSection extends ConsumerWidget {
  final UserProfile user;
  final UserGoal goal;

  const _RecommendationsSection({required this.user, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFoods = ref.read(allFoodsProvider);
    final recommendationEngine = ref.read(recommendationEngineProvider);

    // Filter for vegetarian if needed
    final householdFoods = user.isVegetarian
        ? allFoods.where((f) => f.isVegetarian).toList()
        : allFoods;

    final recommendations = recommendationEngine.recommend(
      user: user,
      goal: goal,
      remainingCalories: goal.dailyCalorieTarget.toDouble() * 0.4,
      remainingProtein: goal.dailyProteinTargetG * 0.3,
      householdFoods: householdFoods.take(40).toList(),
      mealType: MealType.lunch,
    );

    if (recommendations.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '✨ Recommended Combos', subtitle: 'Based on your goals'),
        const SizedBox(height: 10),
        ...recommendations.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RecommendationCard(recommendation: r),
        )),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  final UserGoal goal;

  const _TipsCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final tips = _getTipsForGoal(goal.goalType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Tips for your goal', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getTipsForGoal(WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return [
          'Dal, sabji, and 2 roti is a balanced 400-500 kcal meal.',
          'Use less oil when cooking — 1 tablespoon less saves ~120 kcal.',
          'Start meals with salad or buttermilk (chaas) to feel full.',
          'Eat slowly — it takes 20 min for your brain to register fullness.',
          'Walk 30 minutes daily — burns ~150-200 kcal for 70kg person.',
        ];
      case WeightGoal.gain:
        return [
          'Add paneer, eggs, or dal to every meal for extra protein.',
          'Eat every 3-4 hours — 4-5 meals per day if possible.',
          'Add nuts, ghee, and avocado for healthy calorie surplus.',
          'Strength training helps convert surplus into muscle.',
          'Eat a large breakfast — it helps build appetite for the day.',
        ];
      case WeightGoal.maintain:
        return [
          'Variety is key — try different dals, vegetables each week.',
          'Log your meals — awareness helps maintain consistency.',
          'Keep processed foods and packaged snacks to a minimum.',
          'Hydrate well — often thirst is mistaken for hunger.',
          'Seasonal vegetables are more nutritious and affordable.',
        ];
    }
  }
}
