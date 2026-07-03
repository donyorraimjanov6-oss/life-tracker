import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final Box _tasksBox = Hive.box('tasksBox');
  final Box _settingsBox = Hive.box('settingsBox');

  // Функция, которая мгновенно собирает актуальные цифры из памяти
  Map<String, dynamic> _getUpdatedStats() {
    int total = 0;
    int completed = 0;

    // Считаем все подзадачи во всех папках прямо сейчас
    for (int i = 0; i < _tasksBox.length; i++) {
      final dynamic category = _tasksBox.getAt(i);
      if (category is Map) {
        final List subTasks = category['subTasks'] ?? [];
        for (var task in subTasks) {
          total++;
          if (task['isDone'] == true) {
            completed++;
          }
        }
      }
    }

    double percent = total > 0 ? (completed / total) * 100 : 0.0;

    // Сохраняем сегодняшнюю точку для истории линейного графика
    final String todayKey = DateTime.now().toString().split(' ')[0]; // ГГГГ-ММ-ДД
    _settingsBox.put('history_$todayKey', completed.toDouble());

    return {
      'total': total,
      'completed': completed,
      'percent': percent,
    };
  }

  // Получаем историю за последние 7 дней для линейного графика
  List<FlSpot> _getWeeklySpots() {
    List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final String key = day.toString().split(' ')[0];
      
      final double doneCount = _settingsBox.get('history_$key', defaultValue: 0.0);
      spots.add(FlSpot((6 - i).toDouble(), doneCount));
    }
    return spots;
  }
  // Метод для вывода чисел календаря под графиком
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final now = DateTime.now();
    final int daysAgo = 6 - value.toInt();
    final dayDateTime = now.subtract(Duration(days: daysAgo));
    final String dayNumber = dayDateTime.day.toString();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        dayNumber,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // МГНОВЕННЫЙ РАСЧЕТ ПРИ КАЖДОМ ОТКРЫТИИ ИЛИ КЛИКЕ
    final stats = _getUpdatedStats();
    final int totalTasksToday = stats['total'];
    final int completedTasksToday = stats['completed'];
    final double todayProgressPercent = stats['percent'];
    final int remainingTasks = totalTasksToday - completedTasksToday;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика Успеваемости 📊')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Процент выполнения за сегодня', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          
          // ОБНОВЛЯЕМЫЙ КРУЖОЧЕК С ПРОЦЕНТАМИ
          SizedBox(
            height: 180,
            child: totalTasksToday == 0
                ? const Center(child: Text('Добавьте задания во вкладке задач, чтобы оживить круг!'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: todayProgressPercent,
                          title: todayProgressPercent > 0 ? '${todayProgressPercent.toStringAsFixed(0)}%' : '',
                          radius: 20,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        PieChartSectionData(
                          color: Colors.grey.withOpacity(0.2),
                          value: 100 - todayProgressPercent,
                          title: '',
                          radius: 18,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Сегодня успешно завершено: $completedTasksToday из $totalTasksToday заданий',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          const Divider(height: 40),
          const Text(
            'Прогресс за неделю (по числам календаря)', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          
          // ОБНОВЛЯЕМЫЙ ЛИНЕЙНЫЙ ГРАФИК
          SizedBox(
            height: 200,
            child: totalTasksToday == 0 && _getWeeklySpots().every((spot) => spot.y == 0)
                ? const Center(child: Text('Начните выполнять дела, чтобы линия пошла вверх!'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: _getBottomTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true, 
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                          left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
                        ),
                      ),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getWeeklySpots(),
                          isCurved: true,
                          color: Colors.deepPurple,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true, 
                            color: Colors.deepPurple.withOpacity(0.1)
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
