import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/nutrition_calculator.dart';
import 'custom_food_screen.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  PortionSize? _selectedPortion;
  double _quantity = 1.0;
  late NutritionCalculator _calc;

  @override
  void initState() {
    super.initState();
    _calc = NutritionCalculator();
    if (widget.food.portions.isNotEmpty) {
      _selectedPortion = widget.food.portions.first;
    }
  }

  NutritionRange? get _previewNutrition {
    if (_selectedPortion == null) return null;
    return _calc.calculateForPortion(
      food: widget.food,
      portion: _selectedPortion!,
      quantity: _quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final p = food.per100g;
    final preview = _previewNutrition;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              if (food.isCustom)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomFoodScreen(foodToEdit: food),
                      ),
                    );
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        _categoryEmoji(food.category),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Food names
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name, style: Theme.of(context).textTheme.displaySmall),
                          if (food.nameHi != null)
                            Text(food.nameHi!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                          if (food.nameHinglish != null)
                            Text(food.nameHinglish!, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: food.isVegetarian ? AppColors.primaryContainer : AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            food.isVegetarian ? '🌱 Veg' : '🍗 Non-Veg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: food.isVegetarian ? AppColors.primary : AppColors.secondaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _ConfidenceBadge(confidence: food.confidenceLevel),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Per 100g nutrition
                NutritionRangeCard(
                  nutrition: NutritionRange(
                    caloriesMin: p.caloriesMin,
                    caloriesMax: p.caloriesMax,
                    protein: p.protein,
                    carbs: p.carbs,
                    fat: p.fat,
                    fiber: p.fiber,
                  ),
                  confidence: food.confidenceLevel,
                  confidenceNote: food.confidenceNote ?? 'Values per 100g. Actual values vary by recipe and cooking method.',
                ),

                const SizedBox(height: 20),

                // Portion selector
                if (food.portions.isNotEmpty) ...[
                  Text('Calculate for your serving', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  // Quantity
                  Row(
                    children: [
                      Text('Quantity:', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 12),
                      _QtyBtn(
                        icon: Icons.remove,
                        onTap: _quantity > 0.5 ? () => setState(() => _quantity -= 0.5) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _quantity % 1 == 0 ? _quantity.toInt().toString() : _quantity.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 12),
                      _QtyBtn(
                        icon: Icons.add,
                        onTap: _quantity < 10 ? () => setState(() => _quantity += 0.5) : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text('Portion:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: food.portions.map((portion) {
                      final isSelected = _selectedPortion?.name == portion.name;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPortion = portion),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Column(
                            children: [
                              Text(
                                portion.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '~${portion.weightMinG.round()}–${portion.weightMaxG.round()}g',
                                style: TextStyle(
                                  color: isSelected ? Colors.white70 : AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (preview != null) ...[
                    const SizedBox(height: 16),
                    NutritionRangeCard(nutrition: preview, confidence: food.confidenceLevel),
                  ],
                ],

                const SizedBox(height: 24),

                // Additional nutrients
                if (p.sugar != null || p.sodium != null || p.saturatedFat != null) ...[
                  Text('More nutrients', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        if (p.sugar != null) _NutrientRow('🍬 Sugar', p.sugar!, 'g'),
                        if (p.saturatedFat != null) _NutrientRow('🧈 Saturated fat', p.saturatedFat!, 'g'),
                        if (p.sodium != null) _NutrientRow('🧂 Sodium', p.sodium!, 'mg'),
                        if (p.potassium != null) _NutrientRow('🍌 Potassium', p.potassium!, 'mg'),
                        if (p.calcium != null) _NutrientRow('🦴 Calcium', p.calcium!, 'mg'),
                        if (p.iron != null) _NutrientRow('💪 Iron', p.iron!, 'mg'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Aliases
                if (food.aliases.isNotEmpty) ...[
                  Text('Also known as', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: food.aliases.map((alias) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(alias, style: Theme.of(context).textTheme.bodySmall),
                    )).toList(),
                  ),
                ],

                if (food.source != null) ...[
                  const SizedBox(height: 8),
                  Text('Source: ${food.source}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
                ],

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addToMeal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add to Log'),
      ),
    );
  }

  void _addToMeal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortionSelectorBottomSheet(
        food: widget.food,
        onConfirm: (portion, qty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.food.name} added to log! 🎉'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  String _categoryEmoji(String category) {
    const map = {
      'nonVeg': '🍗', 'veg': '🥗', 'legumes': '🫘', 'grains': '🍚',
      'breads': '🫓', 'dairy': '🥛', 'fruits': '🍎', 'snacks': '🍿',
      'beverages': '🥤', 'sweets': '🍮', 'fats': '🫙', 'southIndian': '🍽️',
    };
    return map[category] ?? '🍲';
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primaryContainer : AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: onTap != null ? AppColors.primary : AppColors.textTertiary),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _NutrientRow(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final ConfidenceLevel confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (confidence) {
      case ConfidenceLevel.high:
        color = AppColors.confidenceHigh;
        label = '✅ High confidence';
        break;
      case ConfidenceLevel.medium:
        color = AppColors.confidenceMedium;
        label = '⚡ Medium confidence';
        break;
      case ConfidenceLevel.low:
        color = AppColors.confidenceLow;
        label = '⚠️ Low confidence';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
