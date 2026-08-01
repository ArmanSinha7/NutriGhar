import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static const _databaseName = "NutriGhar.db";
  static const _databaseVersion = 3;

  AppDatabase._privateConstructor();
  static final AppDatabase instance = AppDatabase._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        subCategory TEXT,
        isVegetarian INTEGER NOT NULL,
        caloriesMin REAL NOT NULL,
        caloriesMax REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL,
        sugar REAL,
        sodium REAL,
        aliases TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        totalCalories REAL NOT NULL,
        totalProtein REAL NOT NULL,
        totalCarbs REAL NOT NULL,
        totalFat REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_items (
        id TEXT PRIMARY KEY,
        mealId TEXT NOT NULL,
        foodId TEXT NOT NULL,
        portionName TEXT NOT NULL,
        quantity REAL NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        FOREIGN KEY (mealId) REFERENCES meals (id) ON DELETE CASCADE,
        FOREIGN KEY (foodId) REFERENCES foods (id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        targetCalories REAL NOT NULL,
        targetProtein REAL NOT NULL,
        targetCarbs REAL NOT NULL,
        targetFat REAL NOT NULL,
        targetWater REAL NOT NULL,
        targetSteps INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        name TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        activityLevel TEXT,
        goal TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id TEXT PRIMARY KEY,
        userProfileId TEXT NOT NULL,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        note TEXT
      )
    ''');

    await _createV2Tables(db);
    await _createV3Tables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add note column to weight_entries
      await db.execute('ALTER TABLE weight_entries ADD COLUMN note TEXT');
      // Add userProfileId column (was missing in v1)
      await db.execute('ALTER TABLE weight_entries ADD COLUMN userProfileId TEXT NOT NULL DEFAULT ""');
      // Create new tables
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
    }
  }

  Future _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE streaks (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        currentStreak INTEGER NOT NULL,
        longestStreak INTEGER NOT NULL,
        lastDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_recipes (
        id TEXT PRIMARY KEY,
        foodId TEXT NOT NULL,
        instructions TEXT,
        FOREIGN KEY (foodId) REFERENCES foods (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_recipe_ingredients (
        id TEXT PRIMARY KEY,
        recipeId TEXT NOT NULL,
        ingredientName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES custom_recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_preps (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        days INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_prep_items (
        id TEXT PRIMARY KEY,
        prepId TEXT NOT NULL,
        day INTEGER NOT NULL,
        mealType TEXT NOT NULL,
        foodId TEXT NOT NULL,
        portionName TEXT NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (prepId) REFERENCES meal_preps (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        status INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Helpers for Database Seeding ---
  
  Future<void> insertFoodBatch(List<Map<String, dynamic>> foods) async {
    final db = await database;
    Batch batch = db.batch();
    for (var food in foods) {
      batch.insert('foods', food, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
