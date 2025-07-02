import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/statistics.dart';
import '../services/database_service.dart';

/// 数据管理Provider
/// 负责管理会话数据的存储、查询和统计分析
class DataProvider extends ChangeNotifier {
  // 私有字段
  final DatabaseService _databaseService = DatabaseService();
  List<Session> _sessions = [];
  Statistics? _currentStatistics;
  bool _isLoading = false;
  String? _error;

  // 统计时间范围
  DateTime _statisticsStartDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _statisticsEndDate = DateTime.now();
  StatisticsTimeRange _timeRange = StatisticsTimeRange.week;

  // Getters
  List<Session> get sessions => List.unmodifiable(_sessions);
  Statistics? get currentStatistics => _currentStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get statisticsStartDate => _statisticsStartDate;
  DateTime get statisticsEndDate => _statisticsEndDate;
  StatisticsTimeRange get timeRange => _timeRange;

  /// 获取今日会话
  List<Session> get todaySessions {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _sessions.where((session) {
      return session.startTime.isAfter(startOfDay) && 
             session.startTime.isBefore(endOfDay);
    }).toList();
  }

  /// 获取本周会话
  List<Session> get thisWeekSessions {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return _sessions.where((session) {
      return session.startTime.isAfter(startOfWeekDay);
    }).toList();
  }

  /// 获取本月会话
  List<Session> get thisMonthSessions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    return _sessions.where((session) {
      return session.startTime.isAfter(startOfMonth);
    }).toList();
  }

  /// 初始化数据
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadSessions();
      await _updateStatistics();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to initialize data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 加载会话数据
  Future<void> _loadSessions() async {
    try {
      _sessions = await _databaseService.getAllSessions();
    } catch (e) {
      debugPrint('Failed to load sessions: $e');
      _sessions = [];
    }
  }

  /// 添加新会话
  Future<void> addSession(Session session) async {
    try {
      final sessionId = await _databaseService.insertSession(session);
      final newSession = session.copyWith(id: sessionId);
      _sessions.add(newSession);
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      await _updateStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to add session: $e');
      notifyListeners();
    }
  }

  /// 更新会话
  Future<void> updateSession(Session session) async {
    try {
      await _databaseService.updateSession(session);
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
        await _updateStatistics();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to update session: $e');
      notifyListeners();
    }
  }

  /// 删除会话
  Future<void> deleteSession(int sessionId) async {
    try {
      await _databaseService.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      await _updateStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to delete session: $e');
      notifyListeners();
    }
  }

  /// 获取指定日期范围的会话
  List<Session> getSessionsInRange(DateTime start, DateTime end) {
    return _sessions.where((session) {
      return session.startTime.isAfter(start) && session.startTime.isBefore(end);
    }).toList();
  }

  /// 更新统计时间范围
  Future<void> updateTimeRange(StatisticsTimeRange newRange) async {
    _timeRange = newRange;
    
    final now = DateTime.now();
    switch (newRange) {
      case StatisticsTimeRange.today:
        _statisticsStartDate = DateTime(now.year, now.month, now.day);
        _statisticsEndDate = _statisticsStartDate.add(const Duration(days: 1));
        break;
      case StatisticsTimeRange.week:
        _statisticsStartDate = now.subtract(Duration(days: now.weekday - 1));
        _statisticsStartDate = DateTime(_statisticsStartDate.year, _statisticsStartDate.month, _statisticsStartDate.day);
        _statisticsEndDate = _statisticsStartDate.add(const Duration(days: 7));
        break;
      case StatisticsTimeRange.month:
        _statisticsStartDate = DateTime(now.year, now.month, 1);
        _statisticsEndDate = DateTime(now.year, now.month + 1, 1);
        break;
      case StatisticsTimeRange.custom:
        // 保持当前的自定义范围
        break;
    }
    
    await _updateStatistics();
    notifyListeners();
  }

  /// 设置自定义时间范围
  Future<void> setCustomTimeRange(DateTime start, DateTime end) async {
    _timeRange = StatisticsTimeRange.custom;
    _statisticsStartDate = start;
    _statisticsEndDate = end;
    
    await _updateStatistics();
    notifyListeners();
  }

  /// 更新统计数据
  Future<void> _updateStatistics() async {
    final rangeSessions = getSessionsInRange(_statisticsStartDate, _statisticsEndDate);
    _currentStatistics = Statistics(
      startDate: _statisticsStartDate,
      endDate: _statisticsEndDate,
      sessions: rangeSessions,
    );
  }

  /// 获取每日统计数据
  List<DailyStatistics> getDailyStatistics(DateTime start, DateTime end) {
    final List<DailyStatistics> dailyStats = [];
    
    for (DateTime date = start; date.isBefore(end); date = date.add(const Duration(days: 1))) {
      final dayStats = DailyStatistics.fromSessions(date, _sessions);
      dailyStats.add(dayStats);
    }
    
    return dailyStats;
  }

  /// 获取最近的会话
  List<Session> getRecentSessions({int limit = 10}) {
    final sortedSessions = List<Session>.from(_sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return sortedSessions.take(limit).toList();
  }

  /// 获取完成的专注会话数量
  int getCompletedFocusSessionsCount({DateTime? since}) {
    var sessions = _sessions.where((s) => 
        s.type == SessionType.focus && s.isCompleted);
    
    if (since != null) {
      sessions = sessions.where((s) => s.startTime.isAfter(since));
    }
    
    return sessions.length;
  }

  /// 获取总专注时间
  Duration getTotalFocusTime({DateTime? since}) {
    var sessions = _sessions.where((s) => 
        s.type == SessionType.focus && s.isCompleted);
    
    if (since != null) {
      sessions = sessions.where((s) => s.startTime.isAfter(since));
    }
    
    return sessions.fold(Duration.zero, (total, session) => 
        total + (session.actualDuration ?? Duration.zero));
  }

  /// 获取平均专注时长
  Duration getAverageFocusTime({DateTime? since}) {
    final completedSessions = getCompletedFocusSessionsCount(since: since);
    if (completedSessions == 0) return Duration.zero;
    
    final totalTime = getTotalFocusTime(since: since);
    return Duration(milliseconds: totalTime.inMilliseconds ~/ completedSessions);
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    try {
      await _databaseService.clearAllSessions();
      _sessions.clear();
      _currentStatistics = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to clear data: $e');
      notifyListeners();
    }
  }

  /// 导出数据
  Map<String, dynamic> exportData() {
    return {
      'sessions': _sessions.map((s) => s.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// 导入数据
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      final sessionsList = data['sessions'] as List<dynamic>;
      final importedSessions = sessionsList
          .map((s) => Session.fromMap(s as Map<String, dynamic>))
          .toList();
      
      // TODO: 保存到数据库
      _sessions.addAll(importedSessions);
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      await _updateStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to import data: $e');
      notifyListeners();
    }
  }

  /// 清除错误状态
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// 统计时间范围枚举
enum StatisticsTimeRange {
  today,
  week,
  month,
  custom,
}

/// 统计时间范围扩展方法
extension StatisticsTimeRangeExtension on StatisticsTimeRange {
  String get displayName {
    switch (this) {
      case StatisticsTimeRange.today:
        return '今日';
      case StatisticsTimeRange.week:
        return '本周';
      case StatisticsTimeRange.month:
        return '本月';
      case StatisticsTimeRange.custom:
        return '自定义';
    }
  }
}
