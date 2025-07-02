import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 音频服务
/// 负责播放提示音、通知音等音频功能
class AudioService {
  static AudioService? _instance;
  late AudioPlayer _audioPlayer;
  
  // 内置音频文件映射
  static const Map<String, String> _builtInSounds = {
    'default': 'sounds/notification.mp3',
    'bell': 'sounds/bell.mp3',
    'chime': 'sounds/chime.mp3',
    'ding': 'sounds/ding.mp3',
    'gentle': 'sounds/gentle.mp3',
  };

  AudioService._internal() {
    _audioPlayer = AudioPlayer();
  }

  factory AudioService() {
    _instance ??= AudioService._internal();
    return _instance!;
  }

  /// 初始化音频服务
  Future<void> initialize() async {
    try {
      // 设置音频播放器配置
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // 预加载内置音频文件
      await _preloadBuiltInSounds();
    } catch (e) {
      debugPrint('Failed to initialize audio service: $e');
    }
  }

  /// 预加载内置音频文件
  Future<void> _preloadBuiltInSounds() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory(path.join(documentsDir.path, 'sounds'));

      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      // 复制内置音频文件到本地存储
      for (final entry in _builtInSounds.entries) {
        final soundName = entry.key;
        final assetPath = 'assets/${entry.value}';
        final localPath = path.join(soundsDir.path, '$soundName.mp3');

        final localFile = File(localPath);
        if (!await localFile.exists()) {
          try {
            final byteData = await rootBundle.load(assetPath);
            await localFile.writeAsBytes(byteData.buffer.asUint8List());
          } catch (e) {
            // 如果音频文件不存在，跳过而不是报错
            debugPrint('Sound file $soundName not found in assets, will use system sound as fallback');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to preload built-in sounds: $e');
    }
  }

  /// 播放内置提示音
  Future<void> playBuiltInSound(String soundName, {double volume = 1.0}) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final soundPath = path.join(documentsDir.path, 'sounds', '$soundName.mp3');
      final soundFile = File(soundPath);
      
      if (await soundFile.exists()) {
        await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
        await _audioPlayer.play(DeviceFileSource(soundPath));
      } else {
        debugPrint('Sound file not found: $soundPath');
        // 尝试播放默认系统音
        await _playSystemSound();
      }
    } catch (e) {
      debugPrint('Failed to play built-in sound: $e');
      await _playSystemSound();
    }
  }

  /// 播放自定义音频文件
  Future<void> playCustomSound(String filePath, {double volume = 1.0}) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        debugPrint('Custom sound file not found: $filePath');
        await _playSystemSound();
      }
    } catch (e) {
      debugPrint('Failed to play custom sound: $e');
      await _playSystemSound();
    }
  }

  /// 播放系统默认提示音
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Failed to play system sound: $e');
    }
  }

  /// 播放会话完成提示音
  Future<void> playSessionCompleteSound({
    String soundName = 'default',
    String? customPath,
    double volume = 1.0,
  }) async {
    if (customPath != null && customPath.isNotEmpty) {
      await playCustomSound(customPath, volume: volume);
    } else {
      await playBuiltInSound(soundName, volume: volume);
    }
  }

  /// 播放注意力提示音
  Future<void> playAttentionPromptSound({
    String soundName = 'gentle',
    double volume = 0.5,
  }) async {
    await playBuiltInSound(soundName, volume: volume);
  }

  /// 播放会话开始提示音
  Future<void> playSessionStartSound({
    String soundName = 'chime',
    double volume = 0.7,
  }) async {
    await playBuiltInSound(soundName, volume: volume);
  }

  /// 停止当前播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }

  /// 暂停当前播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
    }
  }

  /// 恢复播放
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Failed to resume audio: $e');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Failed to set volume: $e');
    }
  }

  /// 获取可用的内置音频列表
  List<String> getBuiltInSounds() {
    return _builtInSounds.keys.toList();
  }

  /// 获取内置音频的显示名称
  String getSoundDisplayName(String soundName) {
    switch (soundName) {
      case 'default':
        return '默认';
      case 'bell':
        return '铃声';
      case 'chime':
        return '钟声';
      case 'ding':
        return '叮咚';
      case 'gentle':
        return '轻柔';
      default:
        return soundName;
    }
  }

  /// 测试播放音频
  Future<void> testSound(String soundName, {double volume = 1.0}) async {
    await playBuiltInSound(soundName, volume: volume);
  }

  /// 验证自定义音频文件
  Future<bool> validateCustomSoundFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // 检查文件扩展名
      final extension = path.extension(filePath).toLowerCase();
      const supportedFormats = ['.mp3', '.wav', '.m4a', '.aac'];
      
      if (!supportedFormats.contains(extension)) {
        return false;
      }

      // 检查文件大小（限制为10MB）
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Failed to validate sound file: $e');
      return false;
    }
  }

  /// 获取音频文件信息
  Future<Map<String, dynamic>?> getAudioFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = path.basename(filePath);
      final extension = path.extension(filePath);
      
      return {
        'name': fileName,
        'path': filePath,
        'size': stat.size,
        'format': extension,
        'modified': stat.modified,
      };
    } catch (e) {
      debugPrint('Failed to get audio file info: $e');
      return null;
    }
  }

  /// 清理临时音频文件
  Future<void> cleanupTempFiles() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory(path.join(documentsDir.path, 'temp_sounds'));
      
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to cleanup temp files: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Failed to dispose audio player: $e');
    }
  }
}
