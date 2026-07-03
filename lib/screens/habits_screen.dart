import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late Box _habitsBox;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _habitsBox = Hive.box('settingsBox');
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Привычки: Трекер 1-40 дней 🗓️')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 40,
          itemBuilder: (context, index) {
            final dayNumber = index + 1;
            final isChecked = _habitsBox.get('day_$dayNumber', defaultValue: false);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _habitsBox.put('day_$dayNumber', !isChecked);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isChecked ? Colors.green : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? Colors.green.shade700 : Colors.grey, 
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isChecked ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
