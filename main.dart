import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: SleepPage());
}

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});
  @override
  _SleepPageState createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  int totalMinutes = 0;
  String animal = '';
  final TextEditingController _controller = TextEditingController();
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() => totalMinutes = _prefs?.getInt('total_sleep') ?? 0);
  }

  Future<void> addSleep() async {
    int minutes = int.parse(_controller.text);
    final data = await ApiService.addSleep(minutes);
    
    _prefs?.setInt('total_sleep', data['total_minutes']);
    setState(() {
      totalMinutes = data['total_minutes'];
      animal = data['animal'];
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Sleep: $totalMinutes minutes', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => addSleep(),
              decoration: const InputDecoration(labelText: 'Add minutes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: addSleep, child: const Text('Add Sleep')),
            const SizedBox(height: 40),
            Text('Your Animal: $animal', style: const TextStyle(fontSize: 32)),
          ],
        ),
      ),
    );
  }
}
