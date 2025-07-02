import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';

/// 注意力提示浮层
/// 用于在专注过程中随机检查用户的注意力状态
class PromptOverlay extends StatefulWidget {
  const PromptOverlay({super.key});

  @override
  State<PromptOverlay> createState() => _PromptOverlayState();
}

class _PromptOverlayState extends State<PromptOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.7 * _opacityAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图标
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 标题
                    Text(
                      '注意力检查',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 提示内容
                    Text(
                      '你现在还在专注吗？',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 响应按钮
                    Row(
                      children: [
                        Expanded(
                          child: _buildResponseButton(
                            context: context,
                            label: '走神了',
                            isAttentive: false,
                            isPrimary: false,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildResponseButton(
                            context: context,
                            label: '我在专注',
                            isAttentive: true,
                            isPrimary: true,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 倒计时提示
                    Consumer<TimerProvider>(
                      builder: (context, timerProvider, child) {
                        return Text(
                          '${timerProvider.settings.promptTimeout.inSeconds} 秒后自动记录为走神',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建响应按钮
  Widget _buildResponseButton({
    required BuildContext context,
    required String label,
    required bool isAttentive,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => _handleResponse(context, isAttentive),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? colorScheme.primary 
              : colorScheme.surfaceVariant,
          foregroundColor: isPrimary 
              ? colorScheme.onPrimary 
              : colorScheme.onSurfaceVariant,
          elevation: isPrimary ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 处理用户响应
  void _handleResponse(BuildContext context, bool isAttentive) {
    _animationController.reverse().then((_) {
      final timerProvider = context.read<TimerProvider>();
      timerProvider.respondToPrompt(isAttentive: isAttentive);
    });
  }
}
