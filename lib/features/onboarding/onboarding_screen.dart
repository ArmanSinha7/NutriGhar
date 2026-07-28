import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/services/nutrition_calculator.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Profile fields
  final _nameController = TextEditingController();
  int? _age;
  Gender? _gender;
  double? _heightCm;
  double? _weightKg;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  WeightGoal _goal = WeightGoal.lose;
  bool _isVegetarian = false;

  final _uuid = const Uuid();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim().isEmpty
        ? 'User'
        : _nameController.text.trim();

    final profile = UserProfile(
      id: _uuid.v4(),
      name: name,
      age: _age,
      gender: _gender,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activityLevel: _activityLevel,
      goal: _goal,
      isVegetarian: _isVegetarian,
      avatarEmoji: '👤',
      isActive: true,
    );

    final profileRepo = ref.read(userProfileRepositoryProvider);
    await profileRepo.saveProfile(profile);
    await profileRepo.setActiveProfile(profile.id);

    // Save goal if we have enough data
    if (_weightKg != null && _heightCm != null && _age != null && _gender != null) {
      final bmrCalc = ref.read(bmrCalculatorProvider);
      final bmr = bmrCalc.calculate(
        weightKg: _weightKg!,
        heightCm: _heightCm!,
        age: _age!,
        gender: _gender!,
      );
      final tdee = bmrCalc.estimateTDEE(bmr, _activityLevel);
      final dailyCalorieTarget = bmrCalc.calculateDailyTarget(tdee, _goal);
      final dailyProtein = bmrCalc.calculateProteinTarget(_weightKg!, _goal);

      final goal = UserGoal(
        userProfileId: profile.id,
        goalType: _goal,
        targetWeightKg: _goal == WeightGoal.lose ? (_weightKg! - 5) : null,
        dailyCalorieTarget: dailyCalorieTarget,
        dailyProteinTargetG: dailyProtein,
        dailyCarbTargetG: dailyCalorieTarget * 0.45 / 4, // 45% from carbs
        dailyFatTargetG: dailyCalorieTarget * 0.3 / 9, // 30% from fat
        dailyFiberTargetG: 30,
        startDate: DateTime.now(),
      );

      final goalRepo = ref.read(goalRepositoryProvider);
      await goalRepo.saveGoal(goal);
    }

    if (mounted) {
      // Refresh providers
      ref.invalidate(activeUserProvider);
      ref.invalidate(allProfilesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _currentPage ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _ProfilePage(
                    nameController: _nameController,
                    age: _age,
                    gender: _gender,
                    isVegetarian: _isVegetarian,
                    onAgeChanged: (v) => setState(() => _age = v),
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onVegChanged: (v) => setState(() => _isVegetarian = v),
                    onNext: _nextPage,
                  ),
                  _BodyPage(
                    height: _heightCm,
                    weight: _weightKg,
                    onHeightChanged: (v) => setState(() => _heightCm = v),
                    onWeightChanged: (v) => setState(() => _weightKg = v),
                    onNext: _nextPage,
                  ),
                  _GoalPage(
                    goal: _goal,
                    activityLevel: _activityLevel,
                    heightCm: _heightCm,
                    weightKg: _weightKg,
                    age: _age,
                    gender: _gender,
                    onGoalChanged: (v) => setState(() => _goal = v),
                    onActivityChanged: (v) => setState(() => _activityLevel = v),
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(child: Text('🥘', style: TextStyle(fontSize: 54))),
          ),
          const SizedBox(height: 24),
          Text(
            'NutriGhar',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Text(
            'न्यूट्रीघर',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your offline Indian nutrition companion 🇮🇳',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Track home-cooked Indian meals, manage your weight, and get personalised recommendations — completely offline.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _FeatureRow(emoji: '🍲', text: 'Indian foods in Hindi & English'),
          const SizedBox(height: 10),
          const _FeatureRow(emoji: '🫓', text: '1 roti, 1 katori, ½ plate portions'),
          const SizedBox(height: 10),
          const _FeatureRow(emoji: '📱', text: '100% offline — no login required'),
          const SizedBox(height: 10),
          const _FeatureRow(emoji: '👨‍👩‍👧', text: 'Multiple family profiles'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Get Started 🚀'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _FeatureRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameController;
  final int? age;
  final Gender? gender;
  final bool isVegetarian;
  final ValueChanged<int?> onAgeChanged;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<bool> onVegChanged;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.nameController,
    required this.age,
    required this.gender,
    required this.isVegetarian,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onVegChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👋 Tell us about yourself', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text('We\'ll use this to personalise your experience.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Priya, Rajan, Kairo...',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age (years)',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            onChanged: (v) => onAgeChanged(int.tryParse(v)),
          ),
          const SizedBox(height: 16),
          Text('Gender', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _GenderChip(label: '👨 Male', value: Gender.male, selected: gender, onSelected: onGenderChanged),
              const SizedBox(width: 8),
              _GenderChip(label: '👩 Female', value: Gender.female, selected: gender, onSelected: onGenderChanged),
              const SizedBox(width: 8),
              _GenderChip(label: '🧑 Other', value: Gender.other, selected: gender, onSelected: onGenderChanged),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('🌱 Vegetarian', style: Theme.of(context).textTheme.titleSmall),
              ),
              Switch.adaptive(
                value: isVegetarian,
                onChanged: onVegChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final Gender value;
  final Gender? selected;
  final ValueChanged<Gender?> onSelected;

  const _GenderChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BodyPage extends StatelessWidget {
  final double? height;
  final double? weight;
  final ValueChanged<double?> onHeightChanged;
  final ValueChanged<double?> onWeightChanged;
  final VoidCallback onNext;

  const _BodyPage({
    required this.height,
    required this.weight,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    double? bmi;
    BMICategory? bmiCategory;
    if (height != null && weight != null && height! > 0 && weight! > 0) {
      final calc = BMICalculator();
      bmi = calc.calculate(weightKg: weight!, heightCm: height!);
      bmiCategory = calc.categorize(bmi);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚖️ Body measurements', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          Text('Used for BMI and calorie calculations. All data stays on your device.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'e.g. 165',
              prefixIcon: Icon(Icons.height_rounded),
              suffixText: 'cm',
            ),
            onChanged: (v) => onHeightChanged(double.tryParse(v)),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Current weight (kg)',
              hintText: 'e.g. 72.5',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              suffixText: 'kg',
            ),
            onChanged: (v) => onWeightChanged(double.tryParse(v)),
          ),
          if (bmi != null && bmiCategory != null) ...[
            const SizedBox(height: 24),
            _QuickBMI(bmi: bmi, category: bmiCategory),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Continue'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onNext,
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBMI extends StatelessWidget {
  final double bmi;
  final BMICategory category;

  const _QuickBMI({required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your BMI: ${bmi.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(category.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends ConsumerWidget {
  final WeightGoal goal;
  final ActivityLevel activityLevel;
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final Gender? gender;
  final ValueChanged<WeightGoal> onGoalChanged;
  final ValueChanged<ActivityLevel> onActivityChanged;
  final VoidCallback onFinish;

  const _GoalPage({
    required this.goal,
    required this.activityLevel,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.gender,
    required this.onGoalChanged,
    required this.onActivityChanged,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int? dailyCalTarget;
    double? bmr;

    if (heightCm != null && weightKg != null && age != null && gender != null) {
      final bmrCalc = ref.read(bmrCalculatorProvider);
      bmr = bmrCalc.calculate(weightKg: weightKg!, heightCm: heightCm!, age: age!, gender: gender!);
      final tdee = bmrCalc.estimateTDEE(bmr, activityLevel);
      dailyCalTarget = bmrCalc.calculateDailyTarget(tdee, goal);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 What\'s your goal?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 28),
          _GoalCard(
            emoji: '⬇️',
            title: 'Lose weight',
            subtitle: 'Calorie deficit + high protein',
            selected: goal == WeightGoal.lose,
            onTap: () => onGoalChanged(WeightGoal.lose),
          ),
          const SizedBox(height: 10),
          _GoalCard(
            emoji: '⚖️',
            title: 'Maintain weight',
            subtitle: 'Balance intake with activity',
            selected: goal == WeightGoal.maintain,
            onTap: () => onGoalChanged(WeightGoal.maintain),
          ),
          const SizedBox(height: 10),
          _GoalCard(
            emoji: '⬆️',
            title: 'Gain weight',
            subtitle: 'Healthy surplus + strength',
            selected: goal == WeightGoal.gain,
            onTap: () => onGoalChanged(WeightGoal.gain),
          ),
          const SizedBox(height: 20),
          Text('Activity level', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<ActivityLevel>(
            value: activityLevel,
            decoration: const InputDecoration(),
            items: ActivityLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(_activityLabel(level), style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) { if (v != null) onActivityChanged(v); },
          ),
          if (dailyCalTarget != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your estimated daily target',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('~$dailyCalTarget kcal/day',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      if (bmr != null)
                        Text('BMR: ~${bmr.round()} kcal/day at rest',
                            style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text('Start Tracking 🎉'),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '* All calculations are estimates. Consult a healthcare professional for medical advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return '🛋️ Sedentary (little/no exercise)';
      case ActivityLevel.lightlyActive:
        return '🚶 Lightly active (1-3 days/week)';
      case ActivityLevel.moderatelyActive:
        return '🏃 Moderately active (3-5 days/week)';
      case ActivityLevel.veryActive:
        return '💪 Very active (6-7 days/week)';
      case ActivityLevel.extraActive:
        return '🏋️ Extra active (physical job + exercise)';
    }
  }
}

class _GoalCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
