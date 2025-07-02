/// 应用设置数据模型
/// 管理所有用户可配置的设置项
class AppSettings {
  // 计时器设置
  final Duration focusDuration;
  final Duration breakDuration;
  final bool autoStartBreak;
  final bool autoStartFocus;

  // 通知与音效设置
  final String notificationSound;
  final double soundVolume;
  final bool enableNotifications;
  final bool enableSoundAlerts;
  final String? customSoundPath;

  // 外观设置
  final ThemeMode themeMode;
  final String primaryColor;
  final double windowOpacity;

  // 系统集成设置
  final bool launchAtStartup;
  final bool minimizeToTray;
  final bool enableIdleDetection;
  final Duration idleThreshold;

  // 注意力监测设置
  final bool enableAttentionMonitoring;
  final double promptFrequencyLambda;
  final Duration promptTimeout;
  final bool enableFlashcards;

  // 数据与隐私设置
  final bool enableDataCollection;
  final bool autoBackup;
  final int dataRetentionDays;

  const AppSettings({
    // 计时器设置默认值
    this.focusDuration = const Duration(minutes: 90),
    this.breakDuration = const Duration(minutes: 20),
    this.autoStartBreak = true,
    this.autoStartFocus = false,

    // 通知与音效设置默认值
    this.notificationSound = 'default',
    this.soundVolume = 0.7,
    this.enableNotifications = true,
    this.enableSoundAlerts = true,
    this.customSoundPath,

    // 外观设置默认值
    this.themeMode = ThemeMode.system,
    this.primaryColor = 'blue',
    this.windowOpacity = 1.0,

    // 系统集成设置默认值
    this.launchAtStartup = false,
    this.minimizeToTray = true,
    this.enableIdleDetection = true,
    this.idleThreshold = const Duration(minutes: 5),

    // 注意力监测设置默认值
    this.enableAttentionMonitoring = true,
    this.promptFrequencyLambda = 0.1,
    this.promptTimeout = const Duration(seconds: 15),
    this.enableFlashcards = false,

    // 数据与隐私设置默认值
    this.enableDataCollection = true,
    this.autoBackup = false,
    this.dataRetentionDays = 90,
  });

  /// 从 SharedPreferences 或数据库加载设置
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      // 计时器设置
      focusDuration: Duration(minutes: map['focus_duration_minutes'] as int? ?? 90),
      breakDuration: Duration(minutes: map['break_duration_minutes'] as int? ?? 20),
      autoStartBreak: map['auto_start_break'] as bool? ?? true,
      autoStartFocus: map['auto_start_focus'] as bool? ?? false,

      // 通知与音效设置
      notificationSound: map['notification_sound'] as String? ?? 'default',
      soundVolume: (map['sound_volume'] as num?)?.toDouble() ?? 0.7,
      enableNotifications: map['enable_notifications'] as bool? ?? true,
      enableSoundAlerts: map['enable_sound_alerts'] as bool? ?? true,
      customSoundPath: map['custom_sound_path'] as String?,

      // 外观设置
      themeMode: ThemeMode.values[map['theme_mode'] as int? ?? ThemeMode.system.index],
      primaryColor: map['primary_color'] as String? ?? 'blue',
      windowOpacity: (map['window_opacity'] as num?)?.toDouble() ?? 1.0,

      // 系统集成设置
      launchAtStartup: map['launch_at_startup'] as bool? ?? false,
      minimizeToTray: map['minimize_to_tray'] as bool? ?? true,
      enableIdleDetection: map['enable_idle_detection'] as bool? ?? true,
      idleThreshold: Duration(minutes: map['idle_threshold_minutes'] as int? ?? 5),

      // 注意力监测设置
      enableAttentionMonitoring: map['enable_attention_monitoring'] as bool? ?? true,
      promptFrequencyLambda: (map['prompt_frequency_lambda'] as num?)?.toDouble() ?? 0.1,
      promptTimeout: Duration(seconds: map['prompt_timeout_seconds'] as int? ?? 15),
      enableFlashcards: map['enable_flashcards'] as bool? ?? false,

      // 数据与隐私设置
      enableDataCollection: map['enable_data_collection'] as bool? ?? true,
      autoBackup: map['auto_backup'] as bool? ?? false,
      dataRetentionDays: map['data_retention_days'] as int? ?? 90,
    );
  }

  /// 转换为 Map 以便存储
  Map<String, dynamic> toMap() {
    return {
      // 计时器设置
      'focus_duration_minutes': focusDuration.inMinutes,
      'break_duration_minutes': breakDuration.inMinutes,
      'auto_start_break': autoStartBreak,
      'auto_start_focus': autoStartFocus,

      // 通知与音效设置
      'notification_sound': notificationSound,
      'sound_volume': soundVolume,
      'enable_notifications': enableNotifications,
      'enable_sound_alerts': enableSoundAlerts,
      'custom_sound_path': customSoundPath,

      // 外观设置
      'theme_mode': themeMode.index,
      'primary_color': primaryColor,
      'window_opacity': windowOpacity,

      // 系统集成设置
      'launch_at_startup': launchAtStartup,
      'minimize_to_tray': minimizeToTray,
      'enable_idle_detection': enableIdleDetection,
      'idle_threshold_minutes': idleThreshold.inMinutes,

      // 注意力监测设置
      'enable_attention_monitoring': enableAttentionMonitoring,
      'prompt_frequency_lambda': promptFrequencyLambda,
      'prompt_timeout_seconds': promptTimeout.inSeconds,
      'enable_flashcards': enableFlashcards,

      // 数据与隐私设置
      'enable_data_collection': enableDataCollection,
      'auto_backup': autoBackup,
      'data_retention_days': dataRetentionDays,
    };
  }

  /// 创建副本并修改部分设置
  AppSettings copyWith({
    Duration? focusDuration,
    Duration? breakDuration,
    bool? autoStartBreak,
    bool? autoStartFocus,
    String? notificationSound,
    double? soundVolume,
    bool? enableNotifications,
    bool? enableSoundAlerts,
    String? customSoundPath,
    ThemeMode? themeMode,
    String? primaryColor,
    double? windowOpacity,
    bool? launchAtStartup,
    bool? minimizeToTray,
    bool? enableIdleDetection,
    Duration? idleThreshold,
    bool? enableAttentionMonitoring,
    double? promptFrequencyLambda,
    Duration? promptTimeout,
    bool? enableFlashcards,
    bool? enableDataCollection,
    bool? autoBackup,
    int? dataRetentionDays,
  }) {
    return AppSettings(
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      notificationSound: notificationSound ?? this.notificationSound,
      soundVolume: soundVolume ?? this.soundVolume,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      windowOpacity: windowOpacity ?? this.windowOpacity,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      enableIdleDetection: enableIdleDetection ?? this.enableIdleDetection,
      idleThreshold: idleThreshold ?? this.idleThreshold,
      enableAttentionMonitoring: enableAttentionMonitoring ?? this.enableAttentionMonitoring,
      promptFrequencyLambda: promptFrequencyLambda ?? this.promptFrequencyLambda,
      promptTimeout: promptTimeout ?? this.promptTimeout,
      enableFlashcards: enableFlashcards ?? this.enableFlashcards,
      enableDataCollection: enableDataCollection ?? this.enableDataCollection,
      autoBackup: autoBackup ?? this.autoBackup,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
    );
  }

  @override
  String toString() {
    return 'AppSettings(focusDuration: $focusDuration, breakDuration: $breakDuration, themeMode: $themeMode)';
  }
}

/// 主题模式枚举
enum ThemeMode {
  system,  // 跟随系统
  light,   // 浅色模式
  dark,    // 深色模式
}

/// 主题模式扩展方法
extension ThemeModeExtension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }
}
