import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/timer_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/data_provider.dart';
import 'screens/main_screen.dart';
import 'models/settings.dart' as models;
// import 'services/system_tray_service.dart';
// import 'services/window_service.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusTimerApp());
}

class FocusTimerApp extends StatelessWidget {
  const FocusTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProxyProvider2<SettingsProvider, DataProvider, TimerProvider>(
          create: (_) => TimerProvider(),
          update: (_, settingsProvider, dataProvider, timerProvider) {
            timerProvider?.updateSettings(settingsProvider.settings);
            timerProvider?.setDataProvider(dataProvider);
            return timerProvider ?? TimerProvider();
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: '专注计时',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: _getThemeMode(settingsProvider.settings.themeMode),
            home: const AppInitializer(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  ThemeMode _getThemeMode(models.ThemeMode themeMode) {
    switch (themeMode) {
      case models.ThemeMode.light:
        return ThemeMode.light;
      case models.ThemeMode.dark:
        return ThemeMode.dark;
      case models.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// 应用初始化器
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _error;
  // final SystemTrayService _systemTrayService = SystemTrayService();
  // final WindowService _windowService = WindowService();
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 初始化设置
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.initialize();

      // 初始化数据
      final dataProvider = context.read<DataProvider>();
      await dataProvider.initialize();

      // 初始化音频服务
      await _audioService.initialize();

      // 初始化窗口服务
      // _windowService.initialize(
      //   onWindowShow: () => _updateTrayShowHideItem(true),
      //   onWindowHide: () => _updateTrayShowHideItem(false),
      // );

      // 初始化系统托盘（如果支持）
      // if (SystemTrayService.isSystemTrayAvailable()) {
      //   await _initializeSystemTray();
      // }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Future<void> _initializeSystemTray() async {
  //   final timerProvider = context.read<TimerProvider>();

  //   await _systemTrayService.initialize(
  //     onShowHide: () => _toggleWindowVisibility(),
  //     onPauseResume: () => _handlePauseResume(timerProvider),
  //     onStop: () => timerProvider.stopSession(),
  //     onExit: () => _exitApplication(),
  //   );

  //   // 监听计时器状态变化以更新托盘
  //   timerProvider.addListener(() => _updateTrayStatus(timerProvider));
  // }

  // void _toggleWindowVisibility() {
  //   _windowService.toggleWindowVisibility();
  // }

  // void _handlePauseResume(TimerProvider timerProvider) {
  //   if (timerProvider.isRunning) {
  //     timerProvider.pauseSession();
  //   } else if (timerProvider.isPaused) {
  //     timerProvider.resumeSession();
  //   } else {
  //     timerProvider.startSession();
  //   }
  // }

  // void _updateTrayShowHideItem(bool isVisible) {
  //   _systemTrayService.updateShowHideMenuItem(isVisible);
  // }

  // void _updateTrayStatus(TimerProvider timerProvider) {
  //   _systemTrayService.updateTrayStatus(
  //     status: timerProvider.currentType.displayName,
  //     remainingTime: timerProvider.formattedRemainingTime,
  //     isRunning: timerProvider.isRunning,
  //     isPaused: timerProvider.isPaused,
  //   );
  // }

  // void _exitApplication() {
  //   _systemTrayService.destroy();
  //   // 在实际应用中，这里应该调用系统退出方法
  //   // SystemNavigator.pop() 或其他平台特定的退出方法
  // }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('应用初始化失败', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化应用...'),
            ],
          ),
        ),
      );
    }

    return const MainScreen();
  }
}