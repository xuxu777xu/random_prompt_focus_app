import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/session.dart';
import '../widgets/statistics_charts.dart';

/// 统计屏幕
/// 展示用户的专注数据分析
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注统计'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (dataProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载统计数据失败',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataProvider.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => dataProvider.initialize(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间范围选择器
                _buildTimeRangeSelector(context, dataProvider, theme),
                
                const SizedBox(height: 24),
                
                // 统计卡片
                _buildStatisticsCards(context, dataProvider, theme),
                
                const SizedBox(height: 24),
                
                // 图表区域
                _buildChartsSection(context, dataProvider, theme),
                
                const SizedBox(height: 24),
                
                // 最近会话列表
                _buildRecentSessions(context, dataProvider, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建时间范围选择器
  Widget _buildTimeRangeSelector(BuildContext context, DataProvider dataProvider, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时间范围',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: StatisticsTimeRange.values.map((range) {
                final isSelected = dataProvider.timeRange == range;
                return FilterChip(
                  label: Text(range.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      dataProvider.updateTimeRange(range);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatisticsCards(BuildContext context, DataProvider dataProvider, ThemeData theme) {
    final statistics = dataProvider.currentStatistics;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '统计概览',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.timer,
              title: '总专注时长',
              value: _formatDuration(statistics?.totalFocusTime ?? Duration.zero),
              theme: theme,
            ),
            _buildStatCard(
              icon: Icons.local_fire_department,
              title: '完成会话',
              value: '${statistics?.completedFocusSessions ?? 0}',
              theme: theme,
            ),
            _buildStatCard(
              icon: Icons.psychology,
              title: '走神次数',
              value: '${statistics?.totalDistractions ?? 0}',
              theme: theme,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              title: '平均时长',
              value: _formatDuration(statistics?.averageFocusSessionDuration ?? Duration.zero),
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图表区域
  Widget _buildChartsSection(BuildContext context, DataProvider dataProvider, ThemeData theme) {
    final statistics = dataProvider.currentStatistics;

    if (statistics == null || statistics.sessions.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无图表数据',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '完成一些专注会话后查看数据可视化',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 生成每日统计数据
    final dailyStats = dataProvider.getDailyStatistics(
      dataProvider.statisticsStartDate,
      dataProvider.statisticsEndDate,
    );

    // 计算最大专注时长用于图表缩放
    final maxDuration = dailyStats.isNotEmpty
        ? dailyStats
            .map((s) => s.focusTime)
            .reduce((a, b) => a > b ? a : b)
        : const Duration(hours: 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '数据可视化',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 专注效率饼图
        FocusEfficiencyPieChart(statistics: statistics),

        const SizedBox(height: 16),

        // 每日专注时长柱状图
        if (dailyStats.isNotEmpty)
          DailyFocusChart(
            dailyStats: dailyStats,
            maxDuration: maxDuration,
          ),

        const SizedBox(height: 16),

        // 专注趋势线图
        if (dailyStats.isNotEmpty)
          FocusTrendLineChart(dailyStats: dailyStats),
      ],
    );
  }

  /// 构建最近会话列表
  Widget _buildRecentSessions(BuildContext context, DataProvider dataProvider, ThemeData theme) {
    final recentSessions = dataProvider.getRecentSessions(limit: 5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近会话',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无会话记录',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '开始你的第一个专注会话吧！',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentSessions.map((session) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                session.type == SessionType.focus
                    ? Icons.timer
                    : Icons.coffee,
                color: session.isCompleted 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              title: Text(session.type.displayName),
              subtitle: Text(
                '${_formatDateTime(session.startTime)} • ${_formatDuration(session.actualDuration ?? session.plannedDuration)}',
              ),
              trailing: Icon(
                session.isCompleted 
                    ? Icons.check_circle 
                    : Icons.cancel,
                color: session.isCompleted 
                    ? Colors.green 
                    : Colors.orange,
              ),
            ),
          )).toList(),
      ],
    );
  }

  /// 格式化时长
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

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
