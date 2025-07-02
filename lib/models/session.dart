/// 专注会话数据模型
/// 用于记录每次专注或休息会话的详细信息
class Session {
  final int? id;
  final SessionType type;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration plannedDuration;
  final Duration? actualDuration;
  final SessionStatus status;
  final int distractionCount;
  final List<String> distractionTimes;
  final String? notes;

  Session({
    this.id,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.actualDuration,
    required this.status,
    this.distractionCount = 0,
    this.distractionTimes = const [],
    this.notes,
  });

  /// 从数据库记录创建 Session 对象
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      type: SessionType.values[map['type'] as int],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      plannedDuration: Duration(milliseconds: map['planned_duration'] as int),
      actualDuration: map['actual_duration'] != null
          ? Duration(milliseconds: map['actual_duration'] as int)
          : null,
      status: SessionStatus.values[map['status'] as int],
      distractionCount: map['distraction_count'] as int? ?? 0,
      distractionTimes: map['distraction_times'] != null
          ? (map['distraction_times'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      notes: map['notes'] as String?,
    );
  }

  /// 转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'planned_duration': plannedDuration.inMilliseconds,
      'actual_duration': actualDuration?.inMilliseconds,
      'status': status.index,
      'distraction_count': distractionCount,
      'distraction_times': distractionTimes.join(','),
      'notes': notes,
    };
  }

  /// 创建副本并修改部分属性
  Session copyWith({
    int? id,
    SessionType? type,
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    SessionStatus? status,
    int? distractionCount,
    List<String>? distractionTimes,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      status: status ?? this.status,
      distractionCount: distractionCount ?? this.distractionCount,
      distractionTimes: distractionTimes ?? this.distractionTimes,
      notes: notes ?? this.notes,
    );
  }

  /// 计算会话效率（实际时间/计划时间）
  double get efficiency {
    if (actualDuration == null || plannedDuration.inMilliseconds == 0) {
      return 0.0;
    }
    return actualDuration!.inMilliseconds / plannedDuration.inMilliseconds;
  }

  /// 是否已完成
  bool get isCompleted => status == SessionStatus.completed;

  /// 是否被中断
  bool get wasInterrupted => status == SessionStatus.interrupted;

  @override
  String toString() {
    return 'Session(id: $id, type: $type, status: $status, duration: ${actualDuration ?? plannedDuration})';
  }
}

/// 会话类型枚举
enum SessionType {
  focus,    // 专注
  rest,     // 休息
}

/// 会话状态枚举
enum SessionStatus {
  running,      // 进行中
  paused,       // 已暂停
  completed,    // 已完成
  interrupted,  // 被中断
  cancelled,    // 已取消
  stopped,      // 已停止
}

/// 会话类型扩展方法
extension SessionTypeExtension on SessionType {
  String get displayName {
    switch (this) {
      case SessionType.focus:
        return '专注';
      case SessionType.rest:
        return '休息';
    }
  }

  String get description {
    switch (this) {
      case SessionType.focus:
        return '专注工作时间';
      case SessionType.rest:
        return '休息放松时间';
    }
  }
}

/// 会话状态扩展方法
extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.running:
        return '进行中';
      case SessionStatus.paused:
        return '已暂停';
      case SessionStatus.completed:
        return '已完成';
      case SessionStatus.interrupted:
        return '被中断';
      case SessionStatus.cancelled:
        return '已取消';
      case SessionStatus.stopped:
        return '已停止';
    }
  }
}
