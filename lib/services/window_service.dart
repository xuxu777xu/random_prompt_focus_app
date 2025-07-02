import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 窗口管理服务
/// 负责管理应用窗口的显示、隐藏、最小化等操作
class WindowService {
  static WindowService? _instance;
  bool _isWindowVisible = true;
  bool _isMinimized = false;

  // 窗口状态回调
  VoidCallback? onWindowShow;
  VoidCallback? onWindowHide;
  VoidCallback? onWindowMinimize;
  VoidCallback? onWindowRestore;

  WindowService._internal();

  factory WindowService() {
    _instance ??= WindowService._internal();
    return _instance!;
  }

  /// 初始化窗口服务
  void initialize({
    VoidCallback? onWindowShow,
    VoidCallback? onWindowHide,
    VoidCallback? onWindowMinimize,
    VoidCallback? onWindowRestore,
  }) {
    this.onWindowShow = onWindowShow;
    this.onWindowHide = onWindowHide;
    this.onWindowMinimize = onWindowMinimize;
    this.onWindowRestore = onWindowRestore;
  }

  /// 显示窗口
  Future<void> showWindow() async {
    try {
      if (!_isWindowVisible) {
        // 使用平台通道调用原生方法显示窗口
        await _callNativeMethod('showWindow');
        _isWindowVisible = true;
        _isMinimized = false;
        onWindowShow?.call();
      }
    } catch (e) {
      debugPrint('Failed to show window: $e');
    }
  }

  /// 隐藏窗口
  Future<void> hideWindow() async {
    try {
      if (_isWindowVisible) {
        // 使用平台通道调用原生方法隐藏窗口
        await _callNativeMethod('hideWindow');
        _isWindowVisible = false;
        onWindowHide?.call();
      }
    } catch (e) {
      debugPrint('Failed to hide window: $e');
    }
  }

  /// 最小化窗口
  Future<void> minimizeWindow() async {
    try {
      await _callNativeMethod('minimizeWindow');
      _isMinimized = true;
      onWindowMinimize?.call();
    } catch (e) {
      debugPrint('Failed to minimize window: $e');
    }
  }

  /// 恢复窗口
  Future<void> restoreWindow() async {
    try {
      await _callNativeMethod('restoreWindow');
      _isMinimized = false;
      _isWindowVisible = true;
      onWindowRestore?.call();
    } catch (e) {
      debugPrint('Failed to restore window: $e');
    }
  }

  /// 切换窗口显示状态
  Future<void> toggleWindowVisibility() async {
    if (_isWindowVisible) {
      await hideWindow();
    } else {
      await showWindow();
    }
  }

  /// 最小化到托盘
  Future<void> minimizeToTray() async {
    await hideWindow();
  }

  /// 从托盘恢复
  Future<void> restoreFromTray() async {
    await showWindow();
    await bringToFront();
  }

  /// 将窗口置于前台
  Future<void> bringToFront() async {
    try {
      await _callNativeMethod('bringToFront');
    } catch (e) {
      debugPrint('Failed to bring window to front: $e');
    }
  }

  /// 设置窗口置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    try {
      await _callNativeMethod('setAlwaysOnTop', {'alwaysOnTop': alwaysOnTop});
    } catch (e) {
      debugPrint('Failed to set always on top: $e');
    }
  }

  /// 设置窗口透明度
  Future<void> setWindowOpacity(double opacity) async {
    try {
      await _callNativeMethod('setWindowOpacity', {'opacity': opacity.clamp(0.0, 1.0)});
    } catch (e) {
      debugPrint('Failed to set window opacity: $e');
    }
  }

  /// 获取窗口位置
  Future<Offset?> getWindowPosition() async {
    try {
      final result = await _callNativeMethod('getWindowPosition');
      if (result != null && result is Map) {
        return Offset(
          (result['x'] as num).toDouble(),
          (result['y'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Failed to get window position: $e');
    }
    return null;
  }

  /// 设置窗口位置
  Future<void> setWindowPosition(Offset position) async {
    try {
      await _callNativeMethod('setWindowPosition', {
        'x': position.dx,
        'y': position.dy,
      });
    } catch (e) {
      debugPrint('Failed to set window position: $e');
    }
  }

  /// 获取窗口大小
  Future<Size?> getWindowSize() async {
    try {
      final result = await _callNativeMethod('getWindowSize');
      if (result != null && result is Map) {
        return Size(
          (result['width'] as num).toDouble(),
          (result['height'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Failed to get window size: $e');
    }
    return null;
  }

  /// 设置窗口大小
  Future<void> setWindowSize(Size size) async {
    try {
      await _callNativeMethod('setWindowSize', {
        'width': size.width,
        'height': size.height,
      });
    } catch (e) {
      debugPrint('Failed to set window size: $e');
    }
  }

  /// 设置窗口最小大小
  Future<void> setMinimumSize(Size size) async {
    try {
      await _callNativeMethod('setMinimumSize', {
        'width': size.width,
        'height': size.height,
      });
    } catch (e) {
      debugPrint('Failed to set minimum size: $e');
    }
  }

  /// 设置窗口最大大小
  Future<void> setMaximumSize(Size size) async {
    try {
      await _callNativeMethod('setMaximumSize', {
        'width': size.width,
        'height': size.height,
      });
    } catch (e) {
      debugPrint('Failed to set maximum size: $e');
    }
  }

  /// 检查窗口是否可见
  bool get isWindowVisible => _isWindowVisible;

  /// 检查窗口是否最小化
  bool get isMinimized => _isMinimized;

  /// 调用原生方法
  Future<dynamic> _callNativeMethod(String method, [Map<String, dynamic>? arguments]) async {
    const platform = MethodChannel('com.focustimer.window');
    try {
      return await platform.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      debugPrint('Platform exception in $method: ${e.message}');
      return null;
    }
  }

  /// 处理系统窗口事件
  void handleSystemWindowEvent(String event) {
    switch (event) {
      case 'minimize':
        _isMinimized = true;
        onWindowMinimize?.call();
        break;
      case 'restore':
        _isMinimized = false;
        _isWindowVisible = true;
        onWindowRestore?.call();
        break;
      case 'hide':
        _isWindowVisible = false;
        onWindowHide?.call();
        break;
      case 'show':
        _isWindowVisible = true;
        onWindowShow?.call();
        break;
    }
  }

  /// 保存窗口状态
  Map<String, dynamic> saveWindowState() {
    return {
      'isVisible': _isWindowVisible,
      'isMinimized': _isMinimized,
    };
  }

  /// 恢复窗口状态
  void restoreWindowState(Map<String, dynamic> state) {
    _isWindowVisible = state['isVisible'] ?? true;
    _isMinimized = state['isMinimized'] ?? false;
  }
}
