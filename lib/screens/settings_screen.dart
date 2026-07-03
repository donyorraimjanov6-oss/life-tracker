import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsScreen({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки ⚙️')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Блок Профиля
          const Center(
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 50, color: Colors.white)),
                SizedBox(height: 8),
                Text('Мой Профиль', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 40),
          // Темы и Уведомления
          SwitchListTile(
            title: const Text('Тёмная тема оформления'),
            secondary: const Icon(Icons.dark_mode),
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Звуки и напоминания'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Будущая логика звуков
            },
          ),
        ],
      ),
    );
  }
}
