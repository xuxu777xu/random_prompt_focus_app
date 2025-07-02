import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/prompt_overlay.dart';
import 'timer_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

/// 主屏幕 - 包含导航和页面管理
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.timer,
      activeIcon: Icons.timer,
      label: '计时器',
      screen: const TimerScreen(),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: '统计',
      screen: const StatisticsScreen(),
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
      screen: const SettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主要内容
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _navigationItems.map((item) => item.screen).toList(),
          ),
          
          // 注意力提示浮层
          Consumer<TimerProvider>(
            builder: (context, timerProvider, child) {
              if (timerProvider.isPromptShowing) {
                return const PromptOverlay();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      destinations: _navigationItems.map((item) {
        final isSelected = _navigationItems.indexOf(item) == _currentIndex;
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: item.label,
        );
      }).toList(),
    );
  }
}

/// 导航项数据类
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
