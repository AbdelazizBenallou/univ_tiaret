import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static const int _dbVersion = 5;
  static const String _dbName = 'univ_tiaret_cache.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_seasons (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_semesters (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level_id INTEGER NOT NULL,
        is_current INTEGER NOT NULL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_modules (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        coefficient TEXT NOT NULL,
        credit INTEGER NOT NULL,
        semester_id INTEGER NOT NULL,
        speciality_id INTEGER,
        level_name TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_activities (
        id INTEGER NOT NULL,
        name TEXT NOT NULL,
        module_id INTEGER NOT NULL,
        cached_at TEXT NOT NULL,
        PRIMARY KEY (id, module_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_lesson_files (
        id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        url TEXT NOT NULL DEFAULT '',
        file_type TEXT NOT NULL DEFAULT '',
        module_id INTEGER NOT NULL,
        activity_type_id INTEGER NOT NULL,
        activity_type TEXT NOT NULL DEFAULT '',
        season_id INTEGER NOT NULL,
        uploaded_at TEXT NOT NULL DEFAULT '',
        cached_at TEXT NOT NULL,
        PRIMARY KEY (id, module_id, activity_type_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL DEFAULT '',
        file_url TEXT NOT NULL DEFAULT '',
        module_id INTEGER NOT NULL DEFAULT 0,
        module_name TEXT NOT NULL DEFAULT '',
        season_id INTEGER NOT NULL DEFAULT 0,
        season_name TEXT NOT NULL DEFAULT '',
        semester_name TEXT NOT NULL DEFAULT '',
        activity_type_id INTEGER NOT NULL DEFAULT 0,
        activity_name TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        date_time TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        email TEXT,
        first_name TEXT,
        last_name TEXT,
        gender TEXT,
        student_id TEXT,
        phone TEXT,
        level_id INTEGER,
        level_name TEXT,
        speciality_id INTEGER,
        speciality_name TEXT,
        roles TEXT,
        status TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS cached_activities');
      await db.execute('DROP TABLE IF EXISTS cached_lesson_files');
      await db.execute('''
        CREATE TABLE cached_activities (
          id INTEGER NOT NULL,
          name TEXT NOT NULL,
          module_id INTEGER NOT NULL,
          cached_at TEXT NOT NULL,
          PRIMARY KEY (id, module_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_lesson_files (
          id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          url TEXT NOT NULL DEFAULT '',
          file_type TEXT NOT NULL DEFAULT '',
          module_id INTEGER NOT NULL,
          activity_type_id INTEGER NOT NULL,
          activity_type TEXT NOT NULL DEFAULT '',
          season_id INTEGER NOT NULL,
          uploaded_at TEXT NOT NULL DEFAULT '',
          cached_at TEXT NOT NULL,
          PRIMARY KEY (id, module_id, activity_type_id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          file_id INTEGER NOT NULL,
          file_name TEXT NOT NULL,
          file_type TEXT NOT NULL DEFAULT '',
          file_url TEXT NOT NULL DEFAULT '',
          module_id INTEGER NOT NULL DEFAULT 0,
          module_name TEXT NOT NULL DEFAULT '',
          season_name TEXT NOT NULL DEFAULT '',
          semester_name TEXT NOT NULL DEFAULT '',
          activity_name TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          date_time TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE favorites ADD COLUMN season_id INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE favorites ADD COLUMN activity_type_id INTEGER NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY,
          email TEXT,
          first_name TEXT,
          last_name TEXT,
          gender TEXT,
          student_id TEXT,
          phone TEXT,
          level_id INTEGER,
          level_name TEXT,
          speciality_id INTEGER,
          speciality_name TEXT,
          roles TEXT,
          status TEXT,
          updated_at TEXT
        )
      ''');
    }
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.execute('DELETE FROM cached_seasons');
    await db.execute('DELETE FROM cached_semesters');
    await db.execute('DELETE FROM cached_modules');
    await db.execute('DELETE FROM cached_activities');
    await db.execute('DELETE FROM cached_lesson_files');
    await db.execute('DELETE FROM favorites');
    await db.execute('DELETE FROM reminders');
    await db.execute('DELETE FROM user_profile');
  }
}
