import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Планы Тренировок 🏋️')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPlanCard(
              context,
              title: 'Тренировки в фитнес зале',
              subtitle: 'Штанги, гантели и тренажеры',
              icon: Icons.fitness_center,
              color: Colors.blue,
              planType: 'gym',
              // Базовый мужской комплекс для зала по умолчанию:
              defaultExercises: ['Жим штанги лежа (4х10)', 'Приседания со штангой (4х8)', 'Становая тяга (3х8)', 'Подтягивания на турнике (4хМАКС)'],
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              context,
              title: 'Дома без приборов',
              subtitle: 'Работа со своим весом и разминка',
              icon: Icons.directions_run,
              color: Colors.green,
              planType: 'home',
              // Комплекс для дома:
              defaultExercises: ['Отжимания от пола (4х15)', 'Приседания со своим весом (4x20)', 'Планка статическая (3х1 мин)', 'Скручивания на пресс (4х25)'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String planType,
    required List<String> defaultExercises,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseListScreen(
                planTitle: title,
                planType: planType,
                themeColor: color,
                defaultExercises: defaultExercises,
              ),
            ),
          );
        },
      ),
    );
  }
}
class ExerciseListScreen extends StatefulWidget {
  final String planTitle;
  final String planType;
  final Color themeColor;
  final List<String> defaultExercises;

  const ExerciseListScreen({
    super.key,
    required this.planTitle,
    required this.planType,
    required this.themeColor,
    required this.defaultExercises,
  });

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  late Box _workoutBox;
  final TextEditingController _exerciseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _workoutBox = Hive.box('tasksBox'); // Используем созданный бокс для хранения
    
    // Если этот план тренировок открыт впервые — наполняем его базой
    if (_workoutBox.get('exercises_${widget.planType}') == null) {
      final initialList = widget.defaultExercises.map((name) => {'name': name, 'isDone': false}).toList();
      _workoutBox.put('exercises_${widget.planType}', initialList);
    }
  }

  List<dynamic> _getExercises() {
    return _workoutBox.get('exercises_${widget.planType}', defaultValue: []);
  }

  void _addExercise() {
    if (_exerciseController.text.trim().isEmpty) return;

    final currentExercises = List.from(_getExercises());
    currentExercises.add({
      'name': _exerciseController.text.trim(),
      'isDone': false,
    });

    setState(() {
      _workoutBox.put('exercises_${widget.planType}', currentExercises);
    });

    _exerciseController.clear();
    Navigator.pop(context);
    _updateStats(); // Обновляем данные для графиков успеваемости
  }

  void _toggleExercise(int index) {
    final currentExercises = List.from(_getExercises());
    currentExercises[index]['isDone'] = !currentExercises[index]['isDone'];

    setState(() {
      _workoutBox.put('exercises_${widget.planType}', currentExercises);
    });
    _updateStats();
  }

  void _deleteExercise(int index) {
    final currentExercises = List.from(_getExercises());
    currentExercises.removeAt(index);

    setState(() {
      _workoutBox.put('exercises_${widget.planType}', currentExercises);
    });
    _updateStats();
  }
  // Считаем прогресс тренировок и передаем его в третью панель статистики
  void _updateStats() {
    final gymList = _workoutBox.get('exercises_gym', defaultValue: []);
    final homeList = _workoutBox.get('exercises_home', defaultValue: []);
    
    int completed = 0;
    int total = gymList.length + homeList.length;

    for (var ex in gymList) { if (ex['isDone'] == true) completed++; }
    for (var ex in homeList) { if (ex['isDone'] == true) completed++; }

    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('stat_completed_exercises', completed);
    settingsBox.put('stat_total_exercises', total);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Добавить упражнение'),
        content: TextField(
          controller: _exerciseController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Упражнение и подходы (напр: Брусья 3х12)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _exerciseController.clear();
              Navigator.pop(context);
            }, 
            child: const Text('Отмена', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            onPressed: _addExercise,
            child: const Text('Добавить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final exercises = _getExercises();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planTitle),
        backgroundColor: widget.themeColor.withOpacity(0.1),
      ),
      body: Column(
        children: [
          // ВЕЛИКОЛЕПНАЯ ВЕРХНЯЯ ШАПКА С МУЖЧИНОЙ-АТЛЕТОМ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.themeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: widget.themeColor.withOpacity(0.2),
                  // Используем встроенную иконку атлета / бодибилдера (спортсмена)
                  child: Icon(Icons.sports_gymnastics, size: 50, color: widget.themeColor),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.planType == 'gym' ? 'РЕЖИМ: МАКСИМУМ СИЛЫ 💪' : 'РЕЖИМ: ТОНУС И ФОРМА 🏠',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.themeColor),
                ),
              ],
            ),
          ),
          
          // Список самих упражнений
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text('Список упражнений пуст. Нажмите +, чтобы добавить!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final item = exercises[index];
                      final bool isDone = item['isDone'] ?? false;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            activeColor: widget.themeColor,
                            value: isDone,
                            onChanged: (val) => _toggleExercise(index),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteExercise(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.themeColor,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
