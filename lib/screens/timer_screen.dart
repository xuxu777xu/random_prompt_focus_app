import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/circular_timer.dart';
import '../models/session.dart';

/// 计时器主屏幕
/// 应用的核心界面，用户大部分时间会停留在此
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer2<TimerProvider, SettingsProvider>(
            builder: (context, timerProvider, settingsProvider, child) {
              return Column(
                children: [
                  // 顶部状态栏
                  _buildTopStatusBar(context, timerProvider, theme),
                  
                  const SizedBox(height: 32),
                  
                  // 中心圆环计时器
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: CircularTimer(
                        size: MediaQuery.of(context).size.width * 0.6,
                        strokeWidth: 16.0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 底部控制按钮
                  _buildControlButtons(context, timerProvider, theme),
                  
                  const SizedBox(height: 16),
                  
                  // 会话信息
                  _buildSessionInfo(context, timerProvider, theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建顶部状态栏
  Widget _buildTopStatusBar(BuildContext context, TimerProvider timerProvider, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 当前会话类型和状态
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timerProvider.currentType.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              timerProvider.status.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        
        // 今日完成的番茄数量
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '今日 0', // TODO: 从 DataProvider 获取实际数据
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(BuildContext context, TimerProvider timerProvider, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 重置/跳过按钮
        _buildSecondaryButton(
          context: context,
          icon: timerProvider.isStopped ? Icons.refresh : Icons.skip_next,
          label: timerProvider.isStopped ? '重置' : '跳过',
          onPressed: () {
            if (timerProvider.isStopped) {
              timerProvider.resetSession();
            } else {
              _showSkipConfirmDialog(context, timerProvider);
            }
          },
          theme: theme,
        ),
        
        const SizedBox(width: 24),
        
        // 主要控制按钮（开始/暂停）
        _buildPrimaryButton(
          context: context,
          timerProvider: timerProvider,
          theme: theme,
        ),
        
        const SizedBox(width: 24),
        
        // 停止按钮
        _buildSecondaryButton(
          context: context,
          icon: Icons.stop,
          label: '停止',
          onPressed: timerProvider.isRunning || timerProvider.isPaused
              ? () => _showStopConfirmDialog(context, timerProvider)
              : null,
          theme: theme,
        ),
      ],
    );
  }

  /// 构建主要控制按钮
  Widget _buildPrimaryButton({
    required BuildContext context,
    required TimerProvider timerProvider,
    required ThemeData theme,
  }) {
    IconData icon;
    String label;
    VoidCallback? onPressed;

    if (timerProvider.isStopped) {
      icon = Icons.play_arrow;
      label = '开始';
      onPressed = () => timerProvider.startSession();
    } else if (timerProvider.isRunning) {
      icon = Icons.pause;
      label = '暂停';
      onPressed = () => timerProvider.pauseSession();
    } else if (timerProvider.isPaused) {
      icon = Icons.play_arrow;
      label = '继续';
      onPressed = () => timerProvider.resumeSession();
    } else {
      icon = Icons.play_arrow;
      label = '开始';
      onPressed = () => timerProvider.startSession();
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建次要控制按钮
  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceVariant,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          shape: const CircleBorder(),
          elevation: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建会话信息
  Widget _buildSessionInfo(BuildContext context, TimerProvider timerProvider, ThemeData theme) {
    if (timerProvider.currentSession == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.timer,
            label: '计划时长',
            value: _formatDuration(timerProvider.currentSession!.plannedDuration),
            theme: theme,
          ),
          _buildInfoItem(
            icon: Icons.psychology,
            label: '走神次数',
            value: '${timerProvider.currentDistractionCount}',
            theme: theme,
          ),
          _buildInfoItem(
            icon: Icons.trending_up,
            label: '进度',
            value: '${(timerProvider.progress * 100).round()}%',
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 显示跳过确认对话框
  void _showSkipConfirmDialog(BuildContext context, TimerProvider timerProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过当前会话'),
        content: Text('确定要跳过当前${timerProvider.currentType.displayName}会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              timerProvider.skipSession();
            },
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }

  /// 显示停止确认对话框
  void _showStopConfirmDialog(BuildContext context, TimerProvider timerProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('停止当前会话'),
        content: const Text('确定要停止当前会话吗？进度将不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              timerProvider.stopSession();
            },
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}分钟';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}小时${remainingMinutes}分钟';
    }
  }
}
