import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/di/providers.dart';
import 'manage_habit_screen.dart';

class HabitTrackerScreen extends ConsumerStatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  ConsumerState<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends ConsumerState<HabitTrackerScreen> with SingleTickerProviderStateMixin {
  DateTime _currentMonth = DateTime.now();
  late TabController _tabController;

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
    final monthStr = DateFormat('yyyy-MM').format(_currentMonth);
    
    final activeHabitsAsync = ref.watch(activeHabitsProvider);
    final logsAsync = ref.watch(habitLogsForMonthProvider(monthStr));

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('✨ Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageHabitScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tracker'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: activeHabitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return _buildEmptyState(context);
          }

          return logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, st) => Center(child: Text('Error loading logs: $e')),
            data: (logs) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildContent(context, habits, logs),
                  _buildAnalyticsContent(context, habits, logs),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Start tracking your daily goals by adding your first habit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageHabitScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Habit> habits, List<HabitLog> logs) {
    return Column(
      children: [
        _buildMonthPicker(),
        Expanded(
          child: _buildGrid(habits, logs),
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Habit> habits, List<HabitLog> logs) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    
    // Create a map for quick lookup: habitId_date -> status
    final logMap = <String, int>{};
    for (var log in logs) {
      logMap['${log.habitId}_${log.date}'] = log.status;
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(40.0),
            columnWidths: const {
              0: FixedColumnWidth(120.0),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
              verticalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                ),
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Habit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                  ),
                  for (int i = 1; i <= daysInMonth; i++)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            '$i',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Habit rows
              for (var habit in habits)
                TableRow(
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(habit.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                habit.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (int i = 1; i <= daysInMonth; i++)
                      _buildCell(habit, i, logMap),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(Habit habit, int day, Map<String, int> logMap) {
    final dateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final key = '${habit.id}_$dateStr';
    final status = logMap[key] ?? 0;
    
    // Check if future
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final now = DateTime.now();
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

    // Handle Frequency logic later. Assuming daily for now.

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        onTap: isFuture ? null : () => _toggleLog(habit.id, dateStr),
        child: Container(
          height: 40,
          color: Colors.transparent, // Important for tap target
          child: Center(
            child: isFuture
                ? const SizedBox()
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: status == 1 ? Color(habit.colorValue) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: status == 1
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLog(String habitId, String dateStr) async {
    final service = ref.read(habitServiceProvider);
    await service.toggleLog(habitId, dateStr, const Uuid().v4());
    
    // Invalidate logs for this month
    final monthStr = DateFormat('yyyy-MM').format(_currentMonth);
    ref.invalidate(habitLogsForMonthProvider(monthStr));
  }

  Widget _buildAnalyticsContent(BuildContext context, List<Habit> habits, List<HabitLog> logs) {
    if (habits.isEmpty) return const SizedBox();

    // Compute basic completion rate per habit for the pie chart
    final habitCompletionCounts = <String, int>{};
    for (var habit in habits) {
      habitCompletionCounts[habit.id] = 0;
    }

    for (var log in logs) {
      if (log.status == 1 && habitCompletionCounts.containsKey(log.habitId)) {
        habitCompletionCounts[log.habitId] = habitCompletionCounts[log.habitId]! + 1;
      }
    }

    // Prepare pie chart sections
    final pieSections = <PieChartSectionData>[];
    for (var habit in habits) {
      final count = habitCompletionCounts[habit.id]!;
      if (count > 0) {
        pieSections.add(
          PieChartSectionData(
            color: Color(habit.colorValue),
            value: count.toDouble(),
            title: '${count}x',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            badgeWidget: Text(habit.icon, style: const TextStyle(fontSize: 16)),
            badgePositionPercentageOffset: .98,
          ),
        );
      }
    }

    // If no data, show empty sections
    if (pieSections.isEmpty) {
      pieSections.add(
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.3),
          value: 1,
          title: '0%',
          radius: 50,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthPicker(),
          const SizedBox(height: AppSpacing.xl),
          
          Text('Habit Consistency', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Distribution of completed habits this month.', style: TextStyle(color: AppColors.textSecondary)),
          
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: pieSections,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          
          Text('Individual Stats', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          
          ...habits.map((habit) {
            final count = habitCompletionCounts[habit.id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(habit.colorValue).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(habit.icon, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(habit.frequency, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: Color(habit.colorValue), fontSize: 20)),
                      const Text('this month', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
