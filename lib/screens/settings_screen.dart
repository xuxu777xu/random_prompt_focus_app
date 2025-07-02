import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings.dart' as models;
import '../services/audio_service.dart';

/// 设置屏幕
/// 提供个性化配置选项
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final settings = settingsProvider.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 计时器设置
              _buildSettingsSection(
                title: '计时器设置',
                icon: Icons.timer,
                children: [
                  _buildSliderTile(
                    title: '专注时长',
                    subtitle: '${settings.focusDuration.inMinutes} 分钟',
                    value: settings.focusDuration.inMinutes.toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 33,
                    onChanged: (value) {
                      settingsProvider.updateFocusDuration(
                        Duration(minutes: value.round()),
                      );
                    },
                  ),
                  _buildSliderTile(
                    title: '休息时长',
                    subtitle: '${settings.breakDuration.inMinutes} 分钟',
                    value: settings.breakDuration.inMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    onChanged: (value) {
                      settingsProvider.updateBreakDuration(
                        Duration(minutes: value.round()),
                      );
                    },
                  ),
                  _buildSwitchTile(
                    title: '自动开始休息',
                    subtitle: '专注结束后自动开始休息',
                    value: settings.autoStartBreak,
                    onChanged: (value) {
                      settingsProvider.updateAutoStartSettings(
                        autoStartBreak: value,
                      );
                    },
                  ),
                  _buildSwitchTile(
                    title: '自动开始专注',
                    subtitle: '休息结束后自动开始专注',
                    value: settings.autoStartFocus,
                    onChanged: (value) {
                      settingsProvider.updateAutoStartSettings(
                        autoStartFocus: value,
                      );
                    },
                  ),
                ],
                theme: theme,
              ),

              const SizedBox(height: 24),

              // 外观设置
              _buildSettingsSection(
                title: '外观设置',
                icon: Icons.palette,
                children: [
                  _buildDropdownTile<models.ThemeMode>(
                    title: '主题模式',
                    subtitle: settings.themeMode.displayName,
                    value: settings.themeMode,
                    items: models.ThemeMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(mode.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateThemeMode(value);
                      }
                    },
                  ),
                ],
                theme: theme,
              ),

              const SizedBox(height: 24),

              // 通知与音效设置
              _buildSettingsSection(
                title: '通知与音效',
                icon: Icons.notifications,
                children: [
                  _buildSwitchTile(
                    title: '启用通知',
                    subtitle: '会话结束时显示通知',
                    value: settings.enableNotifications,
                    onChanged: (value) {
                      settingsProvider.updateNotificationSettings(
                        enableNotifications: value,
                      );
                    },
                  ),
                  _buildSwitchTile(
                    title: '启用提示音',
                    subtitle: '会话结束时播放提示音',
                    value: settings.enableSoundAlerts,
                    onChanged: (value) {
                      settingsProvider.updateNotificationSettings(
                        enableSoundAlerts: value,
                      );
                    },
                  ),
                  _buildSliderTile(
                    title: '音量',
                    subtitle: '${(settings.soundVolume * 100).round()}%',
                    value: settings.soundVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) {
                      settingsProvider.updateNotificationSettings(
                        soundVolume: value,
                      );
                    },
                  ),
                  _buildDropdownTile<String>(
                    title: '提示音',
                    subtitle: AudioService().getSoundDisplayName(settings.notificationSound),
                    value: settings.notificationSound,
                    items: AudioService().getBuiltInSounds().map((sound) {
                      return DropdownMenuItem(
                        value: sound,
                        child: Text(AudioService().getSoundDisplayName(sound)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateNotificationSettings(
                          notificationSound: value,
                        );
                        // 测试播放选中的音频
                        AudioService().testSound(value, volume: settings.soundVolume);
                      }
                    },
                  ),
                ],
                theme: theme,
              ),

              const SizedBox(height: 24),

              // 注意力监测设置
              _buildSettingsSection(
                title: '注意力监测',
                icon: Icons.psychology,
                children: [
                  _buildSwitchTile(
                    title: '启用注意力监测',
                    subtitle: '在专注过程中随机检查注意力',
                    value: settings.enableAttentionMonitoring,
                    onChanged: (value) {
                      settingsProvider.updateAttentionSettings(
                        enableAttentionMonitoring: value,
                      );
                    },
                  ),
                  if (settings.enableAttentionMonitoring) ...[
                    _buildSliderTile(
                      title: '提示频率',
                      subtitle: '${settings.promptFrequencyLambda.toStringAsFixed(2)}',
                      value: settings.promptFrequencyLambda,
                      min: 0.01,
                      max: 1.0,
                      divisions: 99,
                      onChanged: (value) {
                        settingsProvider.updateAttentionSettings(
                          promptFrequencyLambda: value,
                        );
                      },
                    ),
                    _buildSliderTile(
                      title: '响应超时',
                      subtitle: '${settings.promptTimeout.inSeconds} 秒',
                      value: settings.promptTimeout.inSeconds.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 5,
                      onChanged: (value) {
                        settingsProvider.updateAttentionSettings(
                          promptTimeout: Duration(seconds: value.round()),
                        );
                      },
                    ),
                  ],
                ],
                theme: theme,
              ),

              const SizedBox(height: 24),

              // 系统集成设置
              _buildSettingsSection(
                title: '系统集成',
                icon: Icons.integration_instructions,
                children: [
                  _buildSwitchTile(
                    title: '开机自启动',
                    subtitle: '系统启动时自动运行应用',
                    value: settings.launchAtStartup,
                    onChanged: (value) {
                      settingsProvider.updateSystemSettings(
                        launchAtStartup: value,
                      );
                    },
                  ),
                  _buildSwitchTile(
                    title: '最小化到托盘',
                    subtitle: '关闭窗口时最小化到系统托盘',
                    value: settings.minimizeToTray,
                    onChanged: (value) {
                      settingsProvider.updateSystemSettings(
                        minimizeToTray: value,
                      );
                    },
                  ),
                  _buildSwitchTile(
                    title: '空闲检测',
                    subtitle: '检测到空闲时自动暂停计时器',
                    value: settings.enableIdleDetection,
                    onChanged: (value) {
                      settingsProvider.updateSystemSettings(
                        enableIdleDetection: value,
                      );
                    },
                  ),
                  if (settings.enableIdleDetection)
                    _buildSliderTile(
                      title: '空闲阈值',
                      subtitle: '${settings.idleThreshold.inMinutes} 分钟',
                      value: settings.idleThreshold.inMinutes.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      onChanged: (value) {
                        settingsProvider.updateSystemSettings(
                          idleThreshold: Duration(minutes: value.round()),
                        );
                      },
                    ),
                ],
                theme: theme,
              ),

              const SizedBox(height: 24),

              // 重置按钮
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.restore,
                          color: theme.colorScheme.error,
                        ),
                        title: const Text('重置所有设置'),
                        subtitle: const Text('将所有设置恢复为默认值'),
                        onTap: () => _showResetDialog(context, settingsProvider),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 构建滑块设置项
  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          contentPadding: EdgeInsets.zero,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 构建下拉选择设置项
  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// 显示重置确认对话框
  void _showResetDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要将所有设置恢复为默认值吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              settingsProvider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置为默认值')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
