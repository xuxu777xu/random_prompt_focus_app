import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

/// 设置管理Provider
/// 负责管理应用设置的加载、保存和更新
class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  SharedPreferences? _prefs;

  // Getters
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// 初始化设置
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
    } catch (e) {
      debugPrint('Failed to initialize settings: $e');
      // 使用默认设置
      _settings = const AppSettings();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    try {
      final Map<String, dynamic> settingsMap = {};

      // 加载所有设置项
      for (final key in _prefs!.getKeys()) {
        final value = _prefs!.get(key);
        settingsMap[key] = value;
      }

      if (settingsMap.isNotEmpty) {
        _settings = AppSettings.fromMap(settingsMap);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// 保存设置到本地存储
  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      final settingsMap = _settings.toMap();
      
      for (final entry in settingsMap.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await _prefs!.setBool(key, value);
        } else if (value is int) {
          await _prefs!.setInt(key, value);
        } else if (value is double) {
          await _prefs!.setDouble(key, value);
        } else if (value is String) {
          await _prefs!.setString(key, value);
        }
      }
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// 更新设置
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// 更新专注时长
  Future<void> updateFocusDuration(Duration duration) async {
    final newSettings = _settings.copyWith(focusDuration: duration);
    await updateSettings(newSettings);
  }

  /// 更新休息时长
  Future<void> updateBreakDuration(Duration duration) async {
    final newSettings = _settings.copyWith(breakDuration: duration);
    await updateSettings(newSettings);
  }

  /// 更新主题模式
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final newSettings = _settings.copyWith(themeMode: themeMode);
    await updateSettings(newSettings);
  }

  /// 更新通知设置
  Future<void> updateNotificationSettings({
    bool? enableNotifications,
    bool? enableSoundAlerts,
    String? notificationSound,
    double? soundVolume,
  }) async {
    final newSettings = _settings.copyWith(
      enableNotifications: enableNotifications,
      enableSoundAlerts: enableSoundAlerts,
      notificationSound: notificationSound,
      soundVolume: soundVolume,
    );
    await updateSettings(newSettings);
  }

  /// 更新系统集成设置
  Future<void> updateSystemSettings({
    bool? launchAtStartup,
    bool? minimizeToTray,
    bool? enableIdleDetection,
    Duration? idleThreshold,
  }) async {
    final newSettings = _settings.copyWith(
      launchAtStartup: launchAtStartup,
      minimizeToTray: minimizeToTray,
      enableIdleDetection: enableIdleDetection,
      idleThreshold: idleThreshold,
    );
    await updateSettings(newSettings);
  }

  /// 更新注意力监测设置
  Future<void> updateAttentionSettings({
    bool? enableAttentionMonitoring,
    double? promptFrequencyLambda,
    Duration? promptTimeout,
    bool? enableFlashcards,
  }) async {
    final newSettings = _settings.copyWith(
      enableAttentionMonitoring: enableAttentionMonitoring,
      promptFrequencyLambda: promptFrequencyLambda,
      promptTimeout: promptTimeout,
      enableFlashcards: enableFlashcards,
    );
    await updateSettings(newSettings);
  }

  /// 更新自动启动设置
  Future<void> updateAutoStartSettings({
    bool? autoStartBreak,
    bool? autoStartFocus,
  }) async {
    final newSettings = _settings.copyWith(
      autoStartBreak: autoStartBreak,
      autoStartFocus: autoStartFocus,
    );
    await updateSettings(newSettings);
  }

  /// 更新外观设置
  Future<void> updateAppearanceSettings({
    String? primaryColor,
    double? windowOpacity,
  }) async {
    final newSettings = _settings.copyWith(
      primaryColor: primaryColor,
      windowOpacity: windowOpacity,
    );
    await updateSettings(newSettings);
  }

  /// 更新数据设置
  Future<void> updateDataSettings({
    bool? enableDataCollection,
    bool? autoBackup,
    int? dataRetentionDays,
  }) async {
    final newSettings = _settings.copyWith(
      enableDataCollection: enableDataCollection,
      autoBackup: autoBackup,
      dataRetentionDays: dataRetentionDays,
    );
    await updateSettings(newSettings);
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    await updateSettings(const AppSettings());
  }

  /// 导出设置
  Map<String, dynamic> exportSettings() {
    return _settings.toMap();
  }

  /// 导入设置
  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      final newSettings = AppSettings.fromMap(settingsMap);
      await updateSettings(newSettings);
    } catch (e) {
      debugPrint('Failed to import settings: $e');
      throw Exception('Invalid settings format');
    }
  }

  /// 获取设置项的显示值
  String getDisplayValue(String settingKey) {
    switch (settingKey) {
      case 'focusDuration':
        return '${_settings.focusDuration.inMinutes} 分钟';
      case 'breakDuration':
        return '${_settings.breakDuration.inMinutes} 分钟';
      case 'themeMode':
        return _settings.themeMode.displayName;
      case 'soundVolume':
        return '${(_settings.soundVolume * 100).round()}%';
      case 'promptFrequencyLambda':
        return _settings.promptFrequencyLambda.toStringAsFixed(2);
      case 'promptTimeout':
        return '${_settings.promptTimeout.inSeconds} 秒';
      case 'idleThreshold':
        return '${_settings.idleThreshold.inMinutes} 分钟';
      case 'dataRetentionDays':
        return '${_settings.dataRetentionDays} 天';
      default:
        return '';
    }
  }

  /// 验证设置值是否有效
  bool validateSetting(String key, dynamic value) {
    switch (key) {
      case 'focusDuration':
        if (value is Duration) {
          return value.inMinutes >= 15 && value.inMinutes <= 180;
        }
        return false;
      case 'breakDuration':
        if (value is Duration) {
          return value.inMinutes >= 5 && value.inMinutes <= 60;
        }
        return false;
      case 'soundVolume':
        if (value is double) {
          return value >= 0.0 && value <= 1.0;
        }
        return false;
      case 'promptFrequencyLambda':
        if (value is double) {
          return value >= 0.01 && value <= 1.0;
        }
        return false;
      case 'windowOpacity':
        if (value is double) {
          return value >= 0.1 && value <= 1.0;
        }
        return false;
      default:
        return true;
    }
  }
}
