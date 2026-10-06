import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../utils/constants.dart';
import 'sla_service.dart';

/// SQLite persistence via sqflite. Owns the schema, seed data and all
/// queries; controllers never touch SQL directly.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      // Foreign keys are off by default in SQLite; enable on every connection.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE team_members (
        id     TEXT PRIMARY KEY,
        name   TEXT NOT NULL,
        role   TEXT NOT NULL,
        avatar TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id          TEXT PRIMARY KEY,
        title       TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        assigned_to TEXT REFERENCES team_members(id) ON DELETE SET NULL,
        priority    TEXT NOT NULL,
        status      TEXT NOT NULL,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        deadline    INTEGER NOT NULL,
        at_risk_at  INTEGER NOT NULL,
        paused_at   INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_tasks_assigned ON tasks(assigned_to)');
    await db.execute('CREATE INDEX idx_tasks_deadline ON tasks(deadline)');
  }

  // ---------------------------------------------------------------------------
  // Team members
  // ---------------------------------------------------------------------------

  Future<List<TeamMember>> getMembers() async {
    final db = await database;
    final rows = await db.query('team_members', orderBy: 'name ASC');
    return rows.map(TeamMember.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  Future<List<Task>> getTasks() async {
    final db = await database;
    final rows = await db.query('tasks', orderBy: 'deadline ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes every row and re-seeds the demo data.
  Future<void> resetDemoData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('team_members');
    });
    await _seed(db);
  }

  // ---------------------------------------------------------------------------
  // Seed data — timestamps are relative to "now" so every SLA state is
  // visible on first launch.
  // ---------------------------------------------------------------------------

  Future<void> _seed(Database db) async {
    const sla = SlaService();
    final now = DateTime.now();

    const members = [
      TeamMember(
        id: 'm1',
        name: 'Maya Kim',
        role: 'Backend Engineer',
        avatar: 'green',
      ),
      TeamMember(
        id: 'm2',
        name: 'Jordan Lee',
        role: 'Product Engineer',
        avatar: 'blue',
      ),
      TeamMember(
        id: 'm3',
        name: 'Priya Shah',
        role: 'QA Engineer',
        avatar: 'purple',
      ),
      TeamMember(
        id: 'm4',
        name: 'Noah Wilson',
        role: 'Frontend Engineer',
        avatar: 'amber',
      ),
    ];

    Task seed(
      String id,
      String title,
      String description,
      String assignee,
      Priority priority,
      TaskStatus status, {
      required Duration createdAgo,
      required Duration deadlineIn,
      Duration? updatedAgo,
      Duration? pausedAgo,
    }) {
      final created = now.subtract(createdAgo);
      final deadline = now.add(deadlineIn);
      return Task(
        id: id,
        title: title,
        description: description,
        assignedTo: assignee,
        priority: priority,
        status: status,
        createdAt: created,
        updatedAt: now.subtract(updatedAgo ?? const Duration(hours: 5)),
        deadline: deadline,
        atRiskAt: sla.calculateAtRiskAt(created, deadline),
        pausedAt: pausedAgo == null ? null : now.subtract(pausedAgo),
      );
    }

    final tasks = [
      seed(
        't1',
        'Resolve payment retry failures',
        'Investigate why failed card payments are not retried by the billing worker and add an exponential back-off.',
        'm1',
        Priority.high,
        TaskStatus.inProgress,
        createdAgo: const Duration(days: 3),
        deadlineIn: const Duration(hours: -2),
        updatedAgo: const Duration(hours: 1),
      ),
      seed(
        't2',
        'Ship onboarding analytics',
        'Add the approved onboarding events and confirm that each step is represented in the growth dashboard.',
        'm2',
        Priority.medium,
        TaskStatus.paused,
        createdAgo: const Duration(days: 4),
        deadlineIn: const Duration(hours: 6),
        updatedAgo: const Duration(hours: 1),
        pausedAgo: const Duration(hours: 1),
      ),
      seed(
        't3',
        'API rate limit alerts',
        'Alert the on-call engineer when any public endpoint exceeds 80% of its rate limit for five minutes.',
        'm3',
        Priority.medium,
        TaskStatus.completed,
        createdAgo: const Duration(days: 3),
        deadlineIn: const Duration(hours: -10),
        updatedAgo: const Duration(minutes: 28),
      ),
      seed(
        't4',
        'Review accessibility fixes',
        'Verify contrast ratios, focus order and screen-reader labels on the settings screens.',
        'm4',
        Priority.low,
        TaskStatus.todo,
        createdAgo: const Duration(days: 1),
        deadlineIn: const Duration(days: 2),
      ),
      seed(
        't5',
        'Migrate auth tokens to secure storage',
        'Move refresh tokens out of shared preferences into the platform keystore.',
        'm1',
        Priority.high,
        TaskStatus.todo,
        createdAgo: const Duration(days: 2),
        deadlineIn: const Duration(days: 3),
      ),
      seed(
        't6',
        'Fix dashboard chart overflow',
        'The weekly chart overflows on small screens when more than six series are shown.',
        'm4',
        Priority.medium,
        TaskStatus.inProgress,
        createdAgo: const Duration(days: 2),
        deadlineIn: const Duration(hours: 10),
        updatedAgo: const Duration(hours: 3),
      ),
      seed(
        't7',
        'Write regression tests for checkout',
        'Cover the coupon, tax and multi-currency paths with integration tests.',
        'm3',
        Priority.high,
        TaskStatus.inProgress,
        createdAgo: const Duration(days: 1),
        deadlineIn: const Duration(days: 4),
        updatedAgo: const Duration(hours: 2),
      ),
      seed(
        't8',
        'Draft release notes for v1.2',
        'Summarise user-facing changes and known issues for the next store release.',
        'm2',
        Priority.low,
        TaskStatus.completed,
        createdAgo: const Duration(days: 2),
        deadlineIn: const Duration(days: 1),
        updatedAgo: const Duration(hours: 3),
      ),
    ];

    final batch = db.batch();
    for (final m in members) {
      batch.insert('team_members', m.toMap());
    }
    for (final t in tasks) {
      batch.insert('tasks', t.toMap());
    }
    await batch.commit(noResult: true);
  }
}
