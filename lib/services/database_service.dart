import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:uuid/uuid.dart';

import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final Uuid _uuid = const Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'sla_task_tracker.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: \${e.toString()}');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE team_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        initials TEXT NOT NULL,
        role TEXT NOT NULL,
        avatar_color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        assigned_to TEXT REFERENCES team_members(id) ON DELETE SET NULL,
        priority TEXT NOT NULL DEFAULT 'Medium',
        deadline TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Todo',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        at_risk_at TEXT NOT NULL,
        paused_at TEXT
      )
    ''');

    // Seed team members
    final seedMembers = [
      TeamMember(
        id: _uuid.v4(),
        name: 'Maya Kim',
        firstName: 'Maya',
        initials: 'MK',
        role: 'Backend Engineer',
        avatarColor: 'avatar-mint',
      ),
      TeamMember(
        id: _uuid.v4(),
        name: 'Jordan Lee',
        firstName: 'Jordan',
        initials: 'JL',
        role: 'Product Engineer',
        avatarColor: 'avatar-blue',
      ),
      TeamMember(
        id: _uuid.v4(),
        name: 'Priya Shah',
        firstName: 'Priya',
        initials: 'PS',
        role: 'QA Engineer',
        avatarColor: 'avatar-violet',
      ),
      TeamMember(
        id: _uuid.v4(),
        name: 'Noah Wilson',
        firstName: 'Noah',
        initials: 'NW',
        role: 'Frontend Engineer',
        avatarColor: 'avatar-sand',
      ),
    ];

    for (var member in seedMembers) {
      await db.insert('team_members', member.toMap());
    }
  }

  // --- Team Members ---

  Future<List<TeamMember>> getAllMembers() async {
    try {
      final db = await database;
      final results = await db.query('team_members');
      return results.map((e) => TeamMember.fromMap(e)).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch team members: \${e.toString()}');
    }
  }

  Future<TeamMember?> getMemberById(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        'team_members',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return TeamMember.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to fetch team member with ID \$id: \${e.toString()}');
    }
  }

  // --- Tasks ---

  Future<List<Task>> getAllTasks() async {
    try {
      final db = await database;
      // Fetch latest updated tasks first (or ordered by created_at)
      final results = await db.query('tasks', orderBy: 'created_at DESC');
      return results.map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch tasks: \${e.toString()}');
    }
  }

  Future<Task?> getTaskById(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return Task.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to fetch task with ID \$id: \${e.toString()}');
    }
  }

  Future<void> insertTask(Task task) async {
    try {
      final db = await database;
      await db.insert('tasks', task.toMap());
    } catch (e) {
      throw DatabaseException('Failed to insert task: \${e.toString()}');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update task with ID \${task.id}: \${e.toString()}');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final db = await database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete task with ID \$id: \${e.toString()}');
    }
  }
}
