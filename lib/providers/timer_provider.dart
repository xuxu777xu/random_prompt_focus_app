import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/settings.dart';
import 'data_provider.dart';
import '../services/audio_service.dart';

/// 计时器状态管理Provider
/// 负责管理计时器的运行状态、时间计算和会话控制
class TimerProvider extends ChangeNotifier {
  // 私有字段
  Timer? _timer;
  Session? _currentSession;
  Duration _remainingTime = Duration.zero;
  SessionType _currentType = SessionType.focus;
  SessionStatus _status = SessionStatus.stopped;
  AppSettings _settings = const AppSettings();
  DataProvider? _dataProvider;
  final AudioService _audioService = AudioService();

  // 注意力监测相关
  Timer? _attentionTimer;
  bool _isPromptShowing = false;
  int _currentDistractionCount = 0;
  final List<String> _currentDistractionTimes = [];

  // Getters
  Session? get currentSession => _currentSession;
  Duration get remainingTime => _remainingTime;
  SessionType get currentType => _currentType;
  SessionStatus get status => _status;
  AppSettings get settings => _settings;
  bool get isRunning => _status == SessionStatus.running;
  bool get isPaused => _status == SessionStatus.paused;
  bool get isStopped => _status == SessionStatus.stopped;
  bool get isPromptShowing => _isPromptShowing;
  int get currentDistractionCount => _currentDistractionCount;

  /// 计算进度百分比 (0.0 - 1.0)
  double get progress {
    if (_currentSession == null) return 0.0;
    final totalTime = _currentSession!.plannedDuration;
    final elapsedTime = totalTime - _remainingTime;
    return totalTime.inMilliseconds > 0 
        ? elapsedTime.inMilliseconds / totalTime.inMilliseconds 
        : 0.0;
  }

  /// 格式化剩余时间显示
  String get formattedRemainingTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 更新设置
  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// 设置数据提供者
  void setDataProvider(DataProvider dataProvider) {
    _dataProvider = dataProvider;
  }

  /// 开始新的会话
  void startSession({SessionType? type}) {
    final sessionType = type ?? _currentType;
    final duration = sessionType == SessionType.focus
        ? _settings.focusDuration
        : _settings.breakDuration;

    _currentSession = Session(
      type: sessionType,
      startTime: DateTime.now(),
      plannedDuration: duration,
      status: SessionStatus.running,
    );

    _currentType = sessionType;
    _remainingTime = duration;
    _status = SessionStatus.running;
    _currentDistractionCount = 0;
    _currentDistractionTimes.clear();

    _startTimer();
    _startAttentionMonitoring();

    // 播放会话开始提示音
    if (_settings.enableSoundAlerts) {
      _audioService.playSessionStartSound(
        soundName: _settings.notificationSound,
        volume: _settings.soundVolume,
      );
    }

    notifyListeners();
  }

  /// 暂停当前会话
  void pauseSession() {
    if (_status != SessionStatus.running) return;

    _timer?.cancel();
    _attentionTimer?.cancel();
    _status = SessionStatus.paused;
    
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(status: SessionStatus.paused);
    }
    
    notifyListeners();
  }

  /// 恢复会话
  void resumeSession() {
    if (_status != SessionStatus.paused) return;

    _status = SessionStatus.running;
    
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(status: SessionStatus.running);
    }
    
    _startTimer();
    _startAttentionMonitoring();
    
    notifyListeners();
  }

  /// 停止当前会话
  void stopSession() {
    _timer?.cancel();
    _attentionTimer?.cancel();

    if (_currentSession != null) {
      final actualDuration = _currentSession!.plannedDuration - _remainingTime;
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        actualDuration: actualDuration,
        status: SessionStatus.interrupted,
        distractionCount: _currentDistractionCount,
        distractionTimes: List.from(_currentDistractionTimes),
      );

      // 保存会话到数据库
      _saveCurrentSession();
    }

    _status = SessionStatus.stopped;
    _remainingTime = Duration.zero;

    notifyListeners();
  }

  /// 重置计时器
  void resetSession() {
    _timer?.cancel();
    _attentionTimer?.cancel();
    
    _currentSession = null;
    _status = SessionStatus.stopped;
    _remainingTime = Duration.zero;
    _currentDistractionCount = 0;
    _currentDistractionTimes.clear();
    
    notifyListeners();
  }

  /// 跳过当前会话
  void skipSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        actualDuration: _currentSession!.plannedDuration - _remainingTime,
        status: SessionStatus.cancelled,
        distractionCount: _currentDistractionCount,
        distractionTimes: List.from(_currentDistractionTimes),
      );

      // 保存会话到数据库
      _saveCurrentSession();
    }

    // 自动切换到下一个会话类型
    final nextType = _currentType == SessionType.focus
        ? SessionType.rest
        : SessionType.focus;

    if ((_currentType == SessionType.focus && _settings.autoStartBreak) ||
        (_currentType == SessionType.rest && _settings.autoStartFocus)) {
      startSession(type: nextType);
    } else {
      _currentType = nextType;
      resetSession();
    }
  }

  /// 启动计时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }

  /// 完成会话
  void _completeSession() {
    _timer?.cancel();
    _attentionTimer?.cancel();

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        actualDuration: _currentSession!.plannedDuration,
        status: SessionStatus.completed,
        distractionCount: _currentDistractionCount,
        distractionTimes: List.from(_currentDistractionTimes),
      );

      // 播放会话完成提示音
      if (_settings.enableSoundAlerts) {
        _audioService.playSessionCompleteSound(
          soundName: _settings.notificationSound,
          customPath: _settings.customSoundPath,
          volume: _settings.soundVolume,
        );
      }

      // 保存会话到数据库
      _saveCurrentSession();
    }

    _status = SessionStatus.stopped;

    // 自动切换到下一个会话类型
    final nextType = _currentType == SessionType.focus
        ? SessionType.rest
        : SessionType.focus;

    if ((_currentType == SessionType.focus && _settings.autoStartBreak) ||
        (_currentType == SessionType.rest && _settings.autoStartFocus)) {
      startSession(type: nextType);
    } else {
      _currentType = nextType;
      _remainingTime = Duration.zero;
    }

    notifyListeners();
  }

  /// 启动注意力监测
  void _startAttentionMonitoring() {
    if (!_settings.enableAttentionMonitoring || _currentType != SessionType.focus) {
      return;
    }
    
    _scheduleNextPrompt();
  }

  /// 安排下一次注意力提示
  void _scheduleNextPrompt() {
    _attentionTimer?.cancel();
    
    // 使用指数分布算法计算下一次提示的时间间隔
    final lambda = _settings.promptFrequencyLambda;
    final randomValue = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
    final interval = (-1 / lambda) * (1 - randomValue).clamp(0.001, 0.999);
    final delayMinutes = (interval * 60).clamp(1, 30); // 限制在1-30分钟之间
    
    _attentionTimer = Timer(Duration(minutes: delayMinutes.round()), () {
      if (_status == SessionStatus.running && _currentType == SessionType.focus) {
        _showAttentionPrompt();
      }
    });
  }

  /// 显示注意力提示
  void _showAttentionPrompt() {
    _isPromptShowing = true;

    // 播放注意力提示音
    if (_settings.enableSoundAlerts) {
      _audioService.playAttentionPromptSound(
        soundName: 'gentle',
        volume: _settings.soundVolume * 0.7, // 稍微降低音量
      );
    }

    notifyListeners();

    // 设置提示超时
    Timer(_settings.promptTimeout, () {
      if (_isPromptShowing) {
        _handlePromptTimeout();
      }
    });
  }

  /// 处理用户对注意力提示的响应
  void respondToPrompt({required bool isAttentive}) {
    if (!_isPromptShowing) return;
    
    _isPromptShowing = false;
    
    if (!isAttentive) {
      _recordDistraction();
    }
    
    _scheduleNextPrompt();
    notifyListeners();
  }

  /// 处理提示超时
  void _handlePromptTimeout() {
    _isPromptShowing = false;
    _recordDistraction();
    _scheduleNextPrompt();
    notifyListeners();
  }

  /// 记录走神事件
  void _recordDistraction() {
    _currentDistractionCount++;
    _currentDistractionTimes.add(DateTime.now().toIso8601String());
  }

  /// 保存当前会话到数据库
  void _saveCurrentSession() {
    if (_currentSession != null && _dataProvider != null) {
      _dataProvider!.addSession(_currentSession!).catchError((error) {
        debugPrint('Failed to save session: $error');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _attentionTimer?.cancel();
    super.dispose();
  }
}
