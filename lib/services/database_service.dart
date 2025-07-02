import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';

/// 数据库服务
/// 负责 SQLite 数据库的初始化、会话数据的 CRUD 操作
class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 在 Windows 上使用 FFI
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 获取应用文档目录
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'focus_timer.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// 创建数据表
  Future<void> _createTables(Database db, int version) async {
    // 创建会话表
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        planned_duration INTEGER NOT NULL,
        actual_duration INTEGER,
        status INTEGER NOT NULL,
        distraction_count INTEGER DEFAULT 0,
        distraction_times TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    // 创建设置表
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_sessions_start_time ON sessions(start_time)');
    await db.execute('CREATE INDEX idx_sessions_type ON sessions(type)');
    await db.execute('CREATE INDEX idx_sessions_status ON sessions(status)');
  }

  /// 升级数据库
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时的处理逻辑
    if (oldVersion < 2) {
      // 示例：添加新字段
      // await db.execute('ALTER TABLE sessions ADD COLUMN new_field TEXT');
    }
  }

  /// 插入新会话
  Future<int> insertSession(Session session) async {
    final db = await database;
    final sessionMap = session.toMap();
    sessionMap.remove('id'); // 移除 id，让数据库自动生成
    
    return await db.insert('sessions', sessionMap);
  }

  /// 更新会话
  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// 删除会话
  Future<int> deleteSession(int sessionId) async {
    final db = await database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 获取所有会话
  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  /// 获取指定日期范围的会话
  Future<List<Session>> getSessionsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  /// 获取指定类型的会话
  Future<List<Session>> getSessionsByType(SessionType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  /// 获取指定状态的会话
  Future<List<Session>> getSessionsByStatus(SessionStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  /// 获取最近的会话
  Future<List<Session>> getRecentSessions({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return maps.map((map) => Session.fromMap(map)).toList();
  }

  /// 获取今日会话
  Future<List<Session>> getTodaySessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await getSessionsInRange(startOfDay, endOfDay);
  }

  /// 获取本周会话
  Future<List<Session>> getThisWeekSessions() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));
    
    return await getSessionsInRange(startOfWeekDay, endOfWeek);
  }

  /// 获取本月会话
  Future<List<Session>> getThisMonthSessions() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    
    return await getSessionsInRange(startOfMonth, endOfMonth);
  }

  /// 获取统计数据
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE start_time >= ? AND start_time <= ?';
      whereArgs = [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch];
    }

    // 获取基础统计
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        COUNT(CASE WHEN type = 0 THEN 1 END) as focus_sessions,
        COUNT(CASE WHEN type = 1 THEN 1 END) as break_sessions,
        COUNT(CASE WHEN status = 3 THEN 1 END) as completed_sessions,
        SUM(CASE WHEN type = 0 AND status = 3 THEN actual_duration ELSE 0 END) as total_focus_time,
        SUM(CASE WHEN type = 1 AND status = 3 THEN actual_duration ELSE 0 END) as total_break_time,
        SUM(distraction_count) as total_distractions,
        AVG(CASE WHEN type = 0 AND status = 3 THEN actual_duration END) as avg_focus_duration
      FROM sessions $whereClause
    ''', whereArgs);

    return result.first;
  }

  /// 清除所有会话数据
  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('sessions');
  }

  /// 清除旧数据（根据保留天数）
  Future<int> clearOldSessions(int retentionDays) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    return await db.delete(
      'sessions',
      where: 'start_time < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  /// 获取数据库大小
  Future<int> getDatabaseSize() async {
    final db = await database;
    final path = db.path;
    final file = File(path);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 备份数据库
  Future<String> backupDatabase() async {
    final db = await database;
    final sourcePath = db.path;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final backupPath = join(
      documentsDirectory.path,
      'focus_timer_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    
    await File(sourcePath).copy(backupPath);
    return backupPath;
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
