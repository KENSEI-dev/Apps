import 'package:flutter/material.dart';
import 'services/api_service.dart';  // ✅ CORRECT (matches your filename)


void main() => runApp(SleepTrackerApp());

class SleepTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Tracker AI',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: SleepHomePage(),
    );
  }
}

class SleepHomePage extends StatefulWidget {
  @override
  _SleepHomePageState createState() => _SleepHomePageState();
}

class _SleepHomePageState extends State<SleepHomePage> {
  String sleepAnimal = '🐾 Tap to analyze';
  String insight = 'Your personalized sleep insights';
  bool isLoading = false;

  Future<void> analyzeSleep() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getSleepAnalytics('user123');
      setState(() {
        sleepAnimal = data['sleep_animal'];
        insight = data['insight'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        insight = 'Connection error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sleep Tracker AI'), elevation: 0),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 80, color: Colors.indigo),
            SizedBox(height: 32),
            Text('Discover Your Sleep Animal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: isLoading ? null : analyzeSleep,
              icon: Icon(isLoading ? Icons.hourglass_empty : Icons.analytics),
              label: Text(isLoading ? 'Analyzing...' : '🔬 Analyze Sleep'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 48),
            Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text('Your Sleep Animal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Text(sleepAnimal, style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    Text(insight, style: TextStyle(fontSize: 18, height: 1.5), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
