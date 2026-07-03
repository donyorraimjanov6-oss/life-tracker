import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Подключаем все наши экраны из папки screens
import 'screens/tasks_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');
  await Hive.openBox('tasksBox');
  runApp(const LifeTrackerApp());
}
class LifeTrackerApp extends StatefulWidget {
  const LifeTrackerApp({super.key});

  @override
  State<LifeTrackerApp> createState() => _LifeTrackerAppState();
}

class _LifeTrackerAppState extends State<LifeTrackerApp> {
  bool _isDarkMode = false;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settingsBox');
    _isDarkMode = _settingsBox.get('darkMode', defaultValue: false);
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _settingsBox.put('darkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.deepPurple),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigationScreen(onThemeChanged: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}
class MainNavigationScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;
  const MainNavigationScreen({super.key, required this.onThemeChanged, required this.isDarkMode});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Вкладки объявляются прямо здесь, чтобы они перерисовывались ЖИВЬЁМ при каждом переключении
    final List<Widget> screens = [
      const TasksScreen(),
      const WorkoutScreen(),
      const StatsScreen(), // Этот экран теперь будет просыпаться и обновляться мгновенно!
      const HabitsScreen(),
      SettingsScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, 
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        // При клике на иконку мы принудительно обновляем состояние всего приложения
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder_copy), label: 'Задачи'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Тренировки'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Привычки'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}
