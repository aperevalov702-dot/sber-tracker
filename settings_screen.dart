import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _threshold = 2.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threshold = prefs.getDouble('alert_threshold') ?? 2.0;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('alert_threshold', _threshold);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Порог уведомлений',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Уведомление при изменении цены на ±${_threshold.toStringAsFixed(1)}% за день',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _threshold,
                          min: 0.5,
                          max: 10.0,
                          divisions: 19,
                          label: '${_threshold.toStringAsFixed(1)}%',
                          onChanged: (v) => setState(() => _threshold = v),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Сохранить'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'О приложении',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sber Tracker v1.0\n\n'
                          'Данные: Московская биржа (MOEX ISS)\n'
                          'Задержка котировок: ~15 минут\n\n'
                          'Рекомендации основаны на технических индикаторах '
                          '(RSI + скользящие средние) и не являются финансовым советом.\n\n'
                          'Интеграция с «СберИнвестиции» пока недоступна '
                          '(официальный API для внешних приложений появится ориентировочно в 2027 году).',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
