import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import '../database/database.dart';

class HabitService {
  HabitService();

  Future<Database> get db => AppDatabase.instance.database;

  // ─── Habits ────────────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    final database = await db;
    await database.insert(
      'habits',
      {
        'id': habit.id,
        'name': habit.name,
        'icon': habit.icon,
        'colorValue': habit.colorValue,
        'frequency': habit.frequency,
        'createdAt': habit.createdAt.toIso8601String(),
        'isArchived': habit.isArchived ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHabit(Habit habit) async {
    final database = await db;
    await database.update(
      'habits',
      {
        'name': habit.name,
        'icon': habit.icon,
        'colorValue': habit.colorValue,
        'frequency': habit.frequency,
        'isArchived': habit.isArchived ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final database = await db;
    await database.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> getActiveHabits() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'habits',
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return maps.map((e) => _mapToHabit(e)).toList();
  }

  Future<List<Habit>> getAllHabits() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query('habits', orderBy: 'createdAt ASC');
    return maps.map((e) => _mapToHabit(e)).toList();
  }

  Habit _mapToHabit(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['colorValue'] as int,
      frequency: map['frequency'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isArchived: (map['isArchived'] as int) == 1,
    );
  }

  // ─── Logs ──────────────────────────────────────────────────────────────────

  Future<void> logHabit(HabitLog log) async {
    final database = await db;
    await database.insert(
      'habit_logs',
      {
        'id': log.id,
        'habitId': log.habitId,
        'date': log.date,
        'status': log.status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HabitLog>> getLogsForMonth(String monthStr) async {
    // monthStr should be YYYY-MM
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'habit_logs',
      where: 'date LIKE ?',
      whereArgs: ['$monthStr-%'],
    );
    return maps.map((e) => _mapToHabitLog(e)).toList();
  }

  Future<HabitLog?> getLogForDate(String habitId, String date) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    if (maps.isEmpty) return null;
    return _mapToHabitLog(maps.first);
  }

  Future<void> toggleLog(String habitId, String date, String logId) async {
    final existing = await getLogForDate(habitId, date);
    if (existing == null) {
      await logHabit(HabitLog(id: logId, habitId: habitId, date: date, status: 1));
    } else {
      final database = await db;
      final newStatus = existing.status == 1 ? 0 : 1;
      await database.update(
        'habit_logs',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  HabitLog _mapToHabitLog(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      date: map['date'] as String,
      status: map['status'] as int,
    );
  }
}
