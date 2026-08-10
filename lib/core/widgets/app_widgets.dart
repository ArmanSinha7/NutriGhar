import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/nutrition_calculator.dart';

// ─── Macro Progress Bar ─────────────────────────────────────────────────────

class MacroProgressBar extends StatelessWidget {
  final String label;
  final String emoji;
  final double consumed;
  final double target;
  final Color color;
  final String unit;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.emoji,
    required this.consumed,
    required this.target,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isOver = consumed > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Text(
              '${consumed.toStringAsFixed(unit == 'kcal' ? 0 : 1)} / ${target.toStringAsFixed(unit == 'kcal' ? 0 : 0)} $unit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isOver ? AppColors.error : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppColors.error : color,
                ),
                minHeight: 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Radial Calorie Indicator ───────────────────────────────────────────────

class CalorieRingIndicator extends StatelessWidget {
  final double consumed;
  final double target;
  final double size;

  const CalorieRingIndicator({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - consumed).clamp(0, double.infinity).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: AppColors.calorieColor,
                strokeWidth: 10,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${consumed.round()}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                'kcal eaten',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '$remaining left',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.calorieColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.12)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start from top
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── NutritionRange Display ─────────────────────────────────────────────────

class NutritionRangeCard extends StatelessWidget {
  final NutritionRange nutrition;
  final ConfidenceLevel confidence;
  final String? confidenceNote;
  final bool compact;

  const NutritionRangeCard({
    super.key,
    required this.nutrition,
    this.confidence = ConfidenceLevel.medium,
    this.confidenceNote,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    Text('🔥 Calories', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      '~${nutrition.caloriesMin.round()}–${nutrition.caloriesMax.round()} kcal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.calorieColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              _ConfidenceBadge(confidence: confidence),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroChip(emoji: '🥩', label: 'Protein', value: '${nutrition.protein.toStringAsFixed(1)}g', color: AppColors.proteinColor),
                const SizedBox(width: 8),
                _MacroChip(emoji: '🍚', label: 'Carbs', value: '${nutrition.carbs.toStringAsFixed(1)}g', color: AppColors.carbColor),
                const SizedBox(width: 8),
                _MacroChip(emoji: '🥑', label: 'Fat', value: '${nutrition.fat.toStringAsFixed(1)}g', color: AppColors.fatColor),
                const SizedBox(width: 8),
                _MacroChip(emoji: '🌾', label: 'Fiber', value: '${nutrition.fiber.toStringAsFixed(1)}g', color: AppColors.fiberColor),
              ],
            ),
            if (confidenceNote != null) ...[
              const SizedBox(height: 8),
              Text(
                '* $confidenceNote',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
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
        label = 'High';
        break;
      case ConfidenceLevel.medium:
        color = AppColors.confidenceMedium;
        label = 'Medium';
        break;
      case ConfidenceLevel.low:
        color = AppColors.confidenceLow;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'Confidence: $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Food Card ──────────────────────────────────────────────────────────────

class FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool showNutrition;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.showNutrition = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = food.per100g;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: food.isVegetarian
                    ? AppColors.primaryContainer
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(food.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!food.isVegetarian)
                        const Text('🍗', style: TextStyle(fontSize: 12))
                      else
                        const Text('🌱', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (food.nameHi != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      food.nameHi!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                  if (showNutrition) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _NutriBadge(
                          text:
                              '🔥 ~${p.caloriesMin.round()}–${p.caloriesMax.round()} kcal/100g',
                          color: AppColors.calorieColor,
                        ),
                        const SizedBox(width: 6),
                        _NutriBadge(
                          text: '🥩 ${p.protein.toStringAsFixed(1)}g',
                          color: AppColors.proteinColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Favorite button
            if (onFavoriteTap != null)
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.error : AppColors.textTertiary,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category) {
      case 'nonVeg':
        return '🍗';
      case 'veg':
        return '🥗';
      case 'legumes':
        return '🫘';
      case 'grains':
        return '🍚';
      case 'breads':
        return '🫓';
      case 'dairy':
        return '🥛';
      case 'fruits':
        return '🍎';
      case 'snacks':
        return '🍿';
      case 'beverages':
        return '🥤';
      case 'sweets':
        return '🍮';
      case 'fats':
        return '🫙';
      case 'southIndian':
        return '🍽️';
      default:
        return '🍲';
    }
  }
}

class _NutriBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _NutriBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Insight Card ───────────────────────────────────────────────────────────

class InsightCard extends StatelessWidget {
  final NutritionInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (insight.type) {
      case InsightType.positive:
        bgColor = AppColors.primaryContainer;
        break;
      case InsightType.suggestion:
        bgColor = AppColors.secondaryContainer;
        break;
      case InsightType.warning:
        bgColor = AppColors.error.withOpacity(0.1);
        break;
      default:
        bgColor = AppColors.surfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── Portion Selector ───────────────────────────────────────────────────────

class PortionSelectorBottomSheet extends StatefulWidget {
  final FoodItem food;
  final Function(PortionSize portion, double quantity) onConfirm;

  const PortionSelectorBottomSheet({
    super.key,
    required this.food,
    required this.onConfirm,
  });

  @override
  State<PortionSelectorBottomSheet> createState() =>
      _PortionSelectorBottomSheetState();
}

class _PortionSelectorBottomSheetState
    extends State<PortionSelectorBottomSheet> {
  PortionSize? _selectedPortion;
  double _quantity = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.food.portions.isNotEmpty) {
      _selectedPortion = widget.food.portions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portions = widget.food.portions;
    final calc = NutritionCalculator();

    NutritionRange? preview;
    if (_selectedPortion != null) {
      preview = calc.calculateForPortion(
        food: widget.food,
        portion: _selectedPortion!,
        quantity: _quantity,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(widget.food.name, style: Theme.of(context).textTheme.headlineMedium),
          if (widget.food.nameHi != null)
            Text(widget.food.nameHi!, style: Theme.of(context).textTheme.bodyMedium),

          const SizedBox(height: 20),

          // Quantity selector
          Row(
            children: [
              Text('Quantity:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 12),
              _QuantityButton(
                icon: Icons.remove,
                onTap: _quantity > 0.5
                    ? () => setState(() => _quantity = (_quantity - 0.5).clamp(0.5, 10))
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                _quantity % 1 == 0
                    ? _quantity.toInt().toString()
                    : _quantity.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 12),
              _QuantityButton(
                icon: Icons.add,
                onTap: _quantity < 10
                    ? () => setState(() => _quantity += 0.5)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text('Portion size:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),

          // Portion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: portions.map((portion) {
              final isSelected = _selectedPortion?.name == portion.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedPortion = portion),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
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
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Nutrition preview
          if (preview != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.calorieColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PreviewMacro(
                      emoji: '🔥',
                      label: 'kcal',
                      value:
                          '~${preview.caloriesMin.round()}–${preview.caloriesMax.round()}'),
                  _PreviewMacro(
                      emoji: '🥩',
                      label: 'protein',
                      value: '${preview.protein.toStringAsFixed(1)}g'),
                  _PreviewMacro(
                      emoji: '🍚',
                      label: 'carbs',
                      value: '${preview.carbs.toStringAsFixed(1)}g'),
                  _PreviewMacro(
                      emoji: '🥑',
                      label: 'fat',
                      value: '${preview.fat.toStringAsFixed(1)}g'),
                ],
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedPortion != null
                  ? () {
                      widget.onConfirm(_selectedPortion!, _quantity);
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add to Meal Log'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _PreviewMacro extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _PreviewMacro({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

// ─── Recommendation Card ────────────────────────────────────────────────────

class RecommendationCard extends StatelessWidget {
  final MealRecommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = recommendation.estimatedNutrition;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.06),
              AppColors.primaryLight.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              recommendation.reasoning,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _TagChip(
                  text: '🔥 ~${n.caloriesMin.round()}–${n.caloriesMax.round()} kcal',
                  color: AppColors.calorieColor,
                ),
                const SizedBox(width: 6),
                _TagChip(
                  text: '🥩 ${n.protein.toStringAsFixed(0)}g protein',
                  color: AppColors.proteinColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── BMI Gauge ──────────────────────────────────────────────────────────────

class BMIGauge extends StatelessWidget {
  final double bmi;
  final BMICategory category;

  const BMIGauge({super.key, required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (category) {
      case BMICategory.underweight:
        color = AppColors.info;
        break;
      case BMICategory.normal:
        color = AppColors.success;
        break;
      case BMICategory.overweight:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '⚖️ Your BMI',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            bmi.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${category.emoji} ${category.label}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '* BMI is a general screening measure, not a complete health indicator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
