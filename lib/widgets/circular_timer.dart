import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../models/session.dart';

/// 圆环计时器组件
/// 使用 CustomPainter 绘制动态进度圆环和时间显示
class CircularTimer extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Color? textColor;

  const CircularTimer({
    super.key,
    this.size = 300.0,
    this.strokeWidth = 12.0,
    this.backgroundColor,
    this.progressColor,
    this.textColor,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        // 更新动画目标值
        _progressAnimation = Tween<double>(
          begin: _progressAnimation.value,
          end: timerProvider.progress,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        
        // 启动动画
        _animationController.forward(from: 0.0);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 圆环进度指示器
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: CircularTimerPainter(
                      progress: _progressAnimation.value,
                      strokeWidth: widget.strokeWidth,
                      backgroundColor: widget.backgroundColor ?? 
                          colorScheme.outline.withOpacity(0.2),
                      progressColor: widget.progressColor ?? 
                          _getProgressColor(timerProvider.currentType, colorScheme),
                      isRunning: timerProvider.isRunning,
                    ),
                  );
                },
              ),
              
              // 中心内容
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 会话类型指示器
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getProgressColor(timerProvider.currentType, colorScheme)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerProvider.currentType.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getProgressColor(timerProvider.currentType, colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 剩余时间显示
                  Text(
                    timerProvider.formattedRemainingTime,
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: widget.textColor ?? colorScheme.onSurface,
                      fontWeight: FontWeight.w300,
                      fontSize: widget.size * 0.15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 状态指示器
                  Text(
                    _getStatusText(timerProvider.status),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (widget.textColor ?? colorScheme.onSurface)
                          .withOpacity(0.7),
                    ),
                  ),
                  
                  // 走神计数（仅在专注模式下显示）
                  if (timerProvider.currentType == SessionType.focus &&
                      timerProvider.currentDistractionCount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '走神 ${timerProvider.currentDistractionCount} 次',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // 脉冲效果（运行时）
              if (timerProvider.isRunning)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: widget.size + 20,
                      height: widget.size + 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getProgressColor(timerProvider.currentType, colorScheme)
                              .withOpacity(0.3 * (1 - _animationController.value)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getProgressColor(SessionType type, ColorScheme colorScheme) {
    switch (type) {
      case SessionType.focus:
        return colorScheme.primary;
      case SessionType.rest:
        return colorScheme.secondary;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.running:
        return '进行中';
      case SessionStatus.paused:
        return '已暂停';
      case SessionStatus.stopped:
        return '准备开始';
      case SessionStatus.completed:
        return '已完成';
      case SessionStatus.interrupted:
        return '已中断';
      case SessionStatus.cancelled:
        return '已取消';
    }
  }
}

/// 圆环计时器绘制器
class CircularTimerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final bool isRunning;

  CircularTimerPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // 添加渐变效果
      if (isRunning) {
        progressPaint.shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + 2 * math.pi * progress,
          colors: [
            progressColor.withOpacity(0.3),
            progressColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      }

      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // 绘制进度端点
      if (progress < 1.0) {
        final endAngle = startAngle + sweepAngle;
        final endPoint = Offset(
          center.dx + radius * math.cos(endAngle),
          center.dy + radius * math.sin(endAngle),
        );

        final endPointPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(endPoint, strokeWidth / 2, endPointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.isRunning != isRunning;
  }
}
