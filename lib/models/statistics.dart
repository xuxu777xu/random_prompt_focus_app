import 'session.dart';

/// 统计数据模型
/// 用于展示用户的专注数据分析
class Statistics {
  final DateTime startDate;
  final DateTime endDate;
  final List<Session> sessions;

  Statistics({
    required this.startDate,
    required this.endDate,
    required this.sessions,
  });

  /// 总专注时长
  Duration get totalFocusTime {
    return sessions
        .where((s) => s.type == SessionType.focus && s.isCompleted)
        .fold(Duration.zero, (total, session) => total + (session.actualDuration ?? Duration.zero));
  }

  /// 总休息时长
  Duration get totalBreakTime {
    return sessions
        .where((s) => s.type == SessionType.rest && s.isCompleted)
        .fold(Duration.zero, (total, session) => total + (session.actualDuration ?? Duration.zero));
  }

  /// 完成的专注会话数量
  int get completedFocusSessions {
    return sessions
        .where((s) => s.type == SessionType.focus && s.isCompleted)
        .length;
  }

  /// 完成的休息会话数量
  int get completedBreakSessions {
    return sessions
        .where((s) => s.type == SessionType.rest && s.isCompleted)
        .length;
  }

  /// 总走神次数
  int get totalDistractions {
    return sessions
        .where((s) => s.type == SessionType.focus)
        .fold(0, (total, session) => total + session.distractionCount);
  }

  /// 平均专注会话时长
  Duration get averageFocusSessionDuration {
    final focusSessions = sessions
        .where((s) => s.type == SessionType.focus && s.isCompleted)
        .toList();
    
    if (focusSessions.isEmpty) return Duration.zero;
    
    final totalDuration = focusSessions
        .fold(Duration.zero, (total, session) => total + (session.actualDuration ?? Duration.zero));
    
    return Duration(milliseconds: totalDuration.inMilliseconds ~/ focusSessions.length);
  }

  /// 平均每个专注会话的走神次数
  double get averageDistractionsPerSession {
    final focusSessions = sessions
        .where((s) => s.type == SessionType.focus)
        .toList();
    
    if (focusSessions.isEmpty) return 0.0;
    
    return totalDistractions / focusSessions.length;
  }

  /// 专注效率（完成会话数/总会话数）
  double get focusEfficiency {
    final totalFocusSessions = sessions
        .where((s) => s.type == SessionType.focus)
        .length;
    
    if (totalFocusSessions == 0) return 0.0;
    
    return completedFocusSessions / totalFocusSessions;
  }

  /// 按日期分组的专注时长
  Map<DateTime, Duration> get dailyFocusTime {
    final Map<DateTime, Duration> dailyData = {};
    
    for (final session in sessions) {
      if (session.type == SessionType.focus && session.isCompleted) {
        final date = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );
        
        dailyData[date] = (dailyData[date] ?? Duration.zero) + 
            (session.actualDuration ?? Duration.zero);
      }
    }
    
    return dailyData;
  }

  /// 按小时分组的专注时长分布
  Map<int, Duration> get hourlyFocusDistribution {
    final Map<int, Duration> hourlyData = {};
    
    for (final session in sessions) {
      if (session.type == SessionType.focus && session.isCompleted) {
        final hour = session.startTime.hour;
        hourlyData[hour] = (hourlyData[hour] ?? Duration.zero) + 
            (session.actualDuration ?? Duration.zero);
      }
    }
    
    return hourlyData;
  }

  /// 按星期几分组的专注时长
  Map<int, Duration> get weeklyFocusDistribution {
    final Map<int, Duration> weeklyData = {};
    
    for (final session in sessions) {
      if (session.type == SessionType.focus && session.isCompleted) {
        final weekday = session.startTime.weekday;
        weeklyData[weekday] = (weeklyData[weekday] ?? Duration.zero) + 
            (session.actualDuration ?? Duration.zero);
      }
    }
    
    return weeklyData;
  }

  /// 最长连续专注时间
  Duration get longestFocusStreak {
    Duration longest = Duration.zero;
    Duration current = Duration.zero;
    
    final focusSessions = sessions
        .where((s) => s.type == SessionType.focus)
        .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    for (final session in focusSessions) {
      if (session.isCompleted) {
        current += session.actualDuration ?? Duration.zero;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = Duration.zero;
      }
    }
    
    return longest;
  }

  /// 创建周统计
  factory Statistics.weekly(List<Session> allSessions, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekSessions = allSessions
        .where((s) => s.startTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd))
        .toList();
    
    return Statistics(
      startDate: weekStart,
      endDate: weekEnd,
      sessions: weekSessions,
    );
  }

  /// 创建月统计
  factory Statistics.monthly(List<Session> allSessions, DateTime monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    final monthSessions = allSessions
        .where((s) => s.startTime.isAfter(monthStart) && s.startTime.isBefore(monthEnd))
        .toList();
    
    return Statistics(
      startDate: monthStart,
      endDate: monthEnd,
      sessions: monthSessions,
    );
  }

  /// 创建自定义时间范围统计
  factory Statistics.custom(List<Session> allSessions, DateTime start, DateTime end) {
    final customSessions = allSessions
        .where((s) => s.startTime.isAfter(start) && s.startTime.isBefore(end))
        .toList();
    
    return Statistics(
      startDate: start,
      endDate: end,
      sessions: customSessions,
    );
  }

  @override
  String toString() {
    return 'Statistics(${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}: '
           '${completedFocusSessions} sessions, ${totalFocusTime.inMinutes}min focus)';
  }
}

/// 每日统计数据
class DailyStatistics {
  final DateTime date;
  final Duration focusTime;
  final Duration breakTime;
  final int focusSessions;
  final int breakSessions;
  final int distractions;

  DailyStatistics({
    required this.date,
    required this.focusTime,
    required this.breakTime,
    required this.focusSessions,
    required this.breakSessions,
    required this.distractions,
  });

  /// 从会话列表创建每日统计
  factory DailyStatistics.fromSessions(DateTime date, List<Session> sessions) {
    final daySessions = sessions.where((s) {
      final sessionDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return sessionDate == targetDate;
    }).toList();

    return DailyStatistics(
      date: date,
      focusTime: daySessions
          .where((s) => s.type == SessionType.focus && s.isCompleted)
          .fold(Duration.zero, (total, s) => total + (s.actualDuration ?? Duration.zero)),
      breakTime: daySessions
          .where((s) => s.type == SessionType.rest && s.isCompleted)
          .fold(Duration.zero, (total, s) => total + (s.actualDuration ?? Duration.zero)),
      focusSessions: daySessions
          .where((s) => s.type == SessionType.focus && s.isCompleted)
          .length,
      breakSessions: daySessions
          .where((s) => s.type == SessionType.rest && s.isCompleted)
          .length,
      distractions: daySessions
          .where((s) => s.type == SessionType.focus)
          .fold(0, (total, s) => total + s.distractionCount),
    );
  }

  /// 总活动时间
  Duration get totalActiveTime => focusTime + breakTime;

  /// 专注效率
  double get focusRatio {
    if (totalActiveTime == Duration.zero) return 0.0;
    return focusTime.inMilliseconds / totalActiveTime.inMilliseconds;
  }
}
