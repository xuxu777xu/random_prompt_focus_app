import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 系统托盘服务
/// 负责管理系统托盘图标、菜单和交互
class SystemTrayService {
  static SystemTrayService? _instance;
  final SystemTray _systemTray = SystemTray();
  
  // 托盘菜单项
  final Menu _menu = Menu();
  late MenuItem _showHideItem;
  late MenuItem _statusItem;
  late MenuItem _pauseResumeItem;

  // 回调函数
  VoidCallback? onShowHide;
  VoidCallback? onPauseResume;
  VoidCallback? onStop;
  VoidCallback? onExit;

  SystemTrayService._internal();

  factory SystemTrayService() {
    _instance ??= SystemTrayService._internal();
    return _instance!;
  }

  /// 初始化系统托盘
  Future<void> initialize({
    VoidCallback? onShowHide,
    VoidCallback? onPauseResume,
    VoidCallback? onStop,
    VoidCallback? onExit,
  }) async {
    this.onShowHide = onShowHide;
    this.onPauseResume = onPauseResume;
    this.onStop = onStop;
    this.onExit = onExit;

    try {
      // 复制托盘图标到本地
      await _copyTrayIcon();
      
      // 初始化托盘图标
      await _initTrayIcon();
      
      // 创建托盘菜单
      await _createTrayMenu();
      
      // 设置托盘菜单
      await _systemTray.setContextMenu(_menu);
      
      // 设置点击事件
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          onShowHide?.call();
        }
      });
      
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  /// 复制托盘图标到本地存储
  Future<void> _copyTrayIcon() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final iconsDir = Directory(path.join(documentsDir.path, 'icons'));
      
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }

      // 复制不同状态的图标
      final iconFiles = [
        'app_icon.ico',
        'app_icon_running.ico',
        'app_icon_paused.ico',
      ];

      for (final iconFile in iconFiles) {
        final localPath = path.join(iconsDir.path, iconFile);
        final localFile = File(localPath);
        
        if (!await localFile.exists()) {
          try {
            final byteData = await rootBundle.load('assets/icons/$iconFile');
            await localFile.writeAsBytes(byteData.buffer.asUint8List());
          } catch (e) {
            debugPrint('Failed to copy icon $iconFile: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to copy tray icons: $e');
    }
  }

  /// 初始化托盘图标
  Future<void> _initTrayIcon() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final iconPath = path.join(documentsDir.path, 'icons', 'app_icon.ico');
      
      await _systemTray.initSystemTray(
        title: "专注计时",
        iconPath: iconPath,
        toolTip: "专注计时应用",
      );
    } catch (e) {
      debugPrint('Failed to init tray icon: $e');
    }
  }

  /// 创建托盘菜单
  Future<void> _createTrayMenu() async {
    // 状态显示项
    _statusItem = MenuItem(
      label: '准备开始',
      enabled: false,
    );

    // 显示/隐藏窗口
    _showHideItem = MenuItem(
      label: '显示窗口',
      onClicked: (menuItem) => onShowHide?.call(),
    );

    // 暂停/继续
    _pauseResumeItem = MenuItem(
      label: '开始专注',
      onClicked: (menuItem) => onPauseResume?.call(),
    );

    // 停止
    final stopItem = MenuItem(
      label: '停止计时',
      onClicked: (menuItem) => onStop?.call(),
    );

    // 分隔符
    final separator1 = MenuItem.separator();
    final separator2 = MenuItem.separator();

    // 退出
    final exitItem = MenuItem(
      label: '退出应用',
      onClicked: (menuItem) => onExit?.call(),
    );

    // 添加菜单项
    await _menu.buildFrom([
      _statusItem,
      separator1,
      _showHideItem,
      _pauseResumeItem,
      stopItem,
      separator2,
      exitItem,
    ]);
  }

  /// 更新托盘状态
  Future<void> updateTrayStatus({
    required String status,
    required String remainingTime,
    required bool isRunning,
    required bool isPaused,
  }) async {
    try {
      // 更新状态文本
      _statusItem.setLabel('$status - $remainingTime');
      
      // 更新暂停/继续按钮
      if (isRunning) {
        _pauseResumeItem.setLabel('暂停');
      } else if (isPaused) {
        _pauseResumeItem.setLabel('继续');
      } else {
        _pauseResumeItem.setLabel('开始专注');
      }

      // 更新托盘图标
      await _updateTrayIcon(isRunning, isPaused);
      
      // 更新工具提示
      final tooltip = isRunning 
          ? '专注计时 - 进行中 ($remainingTime)'
          : isPaused 
              ? '专注计时 - 已暂停'
              : '专注计时 - 准备开始';
      
      await _systemTray.setToolTip(tooltip);
      
    } catch (e) {
      debugPrint('Failed to update tray status: $e');
    }
  }

  /// 更新托盘图标
  Future<void> _updateTrayIcon(bool isRunning, bool isPaused) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      String iconName;
      
      if (isRunning) {
        iconName = 'app_icon_running.ico';
      } else if (isPaused) {
        iconName = 'app_icon_paused.ico';
      } else {
        iconName = 'app_icon.ico';
      }
      
      final iconPath = path.join(documentsDir.path, 'icons', iconName);
      await _systemTray.setImage(iconPath);
    } catch (e) {
      debugPrint('Failed to update tray icon: $e');
    }
  }

  /// 更新显示/隐藏菜单项
  void updateShowHideMenuItem(bool isWindowVisible) {
    try {
      _showHideItem.setLabel(isWindowVisible ? '隐藏窗口' : '显示窗口');
    } catch (e) {
      debugPrint('Failed to update show/hide menu item: $e');
    }
  }

  /// 显示托盘通知
  Future<void> showNotification({
    required String title,
    required String message,
    Duration? duration,
  }) async {
    try {
      // 注意：system_tray 包可能不支持通知，这里是预留接口
      // 可以考虑使用其他通知库或系统API
      debugPrint('Tray notification: $title - $message');
    } catch (e) {
      debugPrint('Failed to show tray notification: $e');
    }
  }

  /// 销毁系统托盘
  Future<void> destroy() async {
    try {
      await _systemTray.destroy();
    } catch (e) {
      debugPrint('Failed to destroy system tray: $e');
    }
  }

  /// 检查系统托盘是否可用
  static bool isSystemTrayAvailable() {
    // 在 Windows 上通常都支持系统托盘
    return Platform.isWindows;
  }
}
