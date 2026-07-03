import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final Box _tasksBox = Hive.box('tasksBox');
  
  // Текстовые контроллеры для ввода без багов
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();
  
  int _selectedCategoryIndex = 0;

  // Цвета для овальных папок-категорий
  final List<Color> _folderColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.amber,
  ];
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAndResetDailyTasks(); // Автопроверка при запуске приложения
  }

  // Умная функция очистки: выполненные удаляет, невыполненные переносит на завтра
  void _checkAndResetDailyTasks() {
    final Box settingsBox = Hive.box('settingsBox');
    final String todayDate = DateTime.now().toString().split(' ')[0];
    final String lastOpenedDate = settingsBox.get('last_opened_date', defaultValue: '');

    if (todayDate != lastOpenedDate) {
      for (int i = 0; i < _tasksBox.length; i++) {
        final dynamic data = _tasksBox.getAt(i);
        if (data is Map) {
          final Map category = Map.from(data);
          final List subTasks = List.from(category['subTasks'] ?? []);

          // Оставляем только те задания, которые НЕ успели сделать (isDone == false)
          final List unfinishedTasks = subTasks.where((task) => task['isDone'] == false).toList();

          category['subTasks'] = unfinishedTasks;
          _tasksBox.putAt(i, category);
        }
      }
      settingsBox.put('last_opened_date', todayDate);
      setState(() {});
    }
  }
  // 1. Создание новой овальной папки-категории
  void _addCategory() {
    if (_categoryController.text.trim().isEmpty) return;

    final newCategory = {
      'title': _categoryController.text.trim(),
      'colorValue': _folderColors[_selectedColorIndex].value,
      'subTasks': [], 
    };

    setState(() {
      _tasksBox.add(newCategory);
      _selectedCategoryIndex = _tasksBox.length - 1;
      
      final String todayDate = DateTime.now().toString().split(' ')[0];
      Hive.box('settingsBox').put('last_opened_date', todayDate);
    });

    _categoryController.clear();
    Navigator.pop(context);
  }

  // 2. Добавление задания (подзадачи) внутрь папки
  void _addSubTask() {
    if (_subTaskController.text.trim().isEmpty || _tasksBox.isEmpty) return;

    final Map category = Map.from(_tasksBox.getAt(_selectedCategoryIndex) as Map);
    final List subTasks = List.from(category['subTasks'] ?? []);

    subTasks.add({
      'title': _subTaskController.text.trim(),
      'isDone': false,
    });

    category['subTasks'] = subTasks;

    setState(() {
      _tasksBox.putAt(_selectedCategoryIndex, category);
    });

    _subTaskController.clear();
    Navigator.pop(context);
  }

  // 3. Нажатие на галочку (выполнено / не выполнено)
  void _toggleSubTask(int subTaskIndex) {
    final Map category = Map.from(_tasksBox.getAt(_selectedCategoryIndex) as Map);
    final List subTasks = List.from(category['subTasks']);

    subTasks[subTaskIndex]['isDone'] = !subTasks[subTaskIndex]['isDone'];
    category['subTasks'] = subTasks;

    setState(() {
      _tasksBox.putAt(_selectedCategoryIndex, category);
    });
  }

  // 4. Быстрое удаление одного задания кнопкой-крестиком
  void _deleteSubTask(int subTaskIndex) {
    final Map category = Map.from(_tasksBox.getAt(_selectedCategoryIndex) as Map);
    final List subTasks = List.from(category['subTasks']);

    subTasks.removeAt(subTaskIndex);
    category['subTasks'] = subTasks;

    setState(() {
      _tasksBox.putAt(_selectedCategoryIndex, category);
    });
  }

  // 5. Полное удаление всей овальной папки
  void _deleteCurrentCategory() {
    if (_tasksBox.isEmpty) return;
    setState(() {
      _tasksBox.deleteAt(_selectedCategoryIndex);
      if (_selectedCategoryIndex > 0) {
        _selectedCategoryIndex--;
      }
    });
  }
  // Всплывающее окно для создания Новой Папки
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Создать новую папку'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _categoryController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Название папки',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Выберите цвет:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 45,
                      width: double.maxFinite,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _folderColors.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                _selectedColorIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _folderColors[index],
                                shape: BoxShape.circle,
                                border: _selectedColorIndex == index
                                    ? Border.all(color: Colors.black, width: 3)
                                    : Border.all(color: Colors.transparent, width: 3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _categoryController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_categoryController.text.trim().isNotEmpty) {
                      _addCategory();
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Всплывающее окно для добавления Задания внутрь папки
  void _showAddSubTaskDialog() {
    if (_tasksBox.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить задание в папку'),
          content: TextField(
            controller: _subTaskController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Что нужно сделать?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _subTaskController.clear();
                Navigator.pop(context);
              },
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_subTaskController.text.trim().isNotEmpty) {
                  _addSubTask();
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    Map? currentCategory;
    List subTasks = [];
    Color currentCategoryColor = Colors.deepPurple;

    if (_tasksBox.isNotEmpty) {
      if (_selectedCategoryIndex >= _tasksBox.length) {
        _selectedCategoryIndex = _tasksBox.length - 1;
      }
      final dynamic data = _tasksBox.getAt(_selectedCategoryIndex);
      if (data is Map) {
        currentCategory = data;
        subTasks = currentCategory['subTasks'] ?? [];
        currentCategoryColor = Color(currentCategory['colorValue']);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер Задач 📁'),
        actions: [
          if (_tasksBox.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Удалить эту папку',
              onPressed: _deleteCurrentCategory,
            )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasksBox.length + 1,
              itemBuilder: (context, index) {
                if (index == _tasksBox.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Новая папка'),
                      onPressed: _showAddCategoryDialog,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }

                final dynamic data = _tasksBox.getAt(index);
                if (data is! Map) return const SizedBox.shrink();

                final Map category = data;
                final Color folderColor = Color(category['colorValue']);
                final bool isSelected = _selectedCategoryIndex == index;

                // СЧЁТЧИК: Считаем только НЕВЫПОЛНЕННЫЕ задачи в папке
                final List folderSubTasks = category['subTasks'] ?? [];
                final int remainingTasks = folderSubTasks.where((t) => t['isDone'] == false).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      remainingTasks > 0 ? '${category['title']} ($remainingTasks)' : category['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : folderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: folderColor,
                    backgroundColor: folderColor.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: folderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _tasksBox.isEmpty
                ? const Center(child: Text('Создайте вашу первую папку сверху 👆'))
                : subTasks.isEmpty
                    ? Center(
                        child: Text(
                          'В папке "${currentCategory?['title']}" ещё нет заданий.\nНажмите Плюс снизу, чтобы добавить!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subTasks.length,
                        itemBuilder: (context, index) {
                          final subTask = subTasks[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Checkbox(
                                activeColor: currentCategoryColor,
                                value: subTask['isDone'],
                                onChanged: (val) => _toggleSubTask(index),
                              ),
                              title: Text(
                                subTask['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: subTask['isDone'] ? TextDecoration.lineThrough : null,
                                  color: subTask['isDone'] ? Colors.grey : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () => _deleteSubTask(index),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _tasksBox.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: currentCategoryColor,
              onPressed: _showAddSubTaskDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
