import 'package:flutter/material.dart';

class IconTestScreen extends StatelessWidget {
  const IconTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Testing Various Icons:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Test 1: Arrow Back in Container
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Test 1: arrow_back in Container'),
            const SizedBox(height: 20),

            // Test 2: Chevron Left
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Test 2: chevron_left'),
            const SizedBox(height: 20),

            // Test 3: Close
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.close, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Test 3: close'),
            const SizedBox(height: 20),

            // Test 4: Menu
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.menu, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Test 4: menu'),
            const SizedBox(height: 20),

            // Test 5: Home
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.home, color: Colors.black, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Test 5: home'),
            const SizedBox(height: 20),

            // Test 6: AppBar with Icon
            const SizedBox(height: 30),
            const Text('Test 6: AppBar Icon Button Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {},
                  ),
                  const Text('AppBar Icon Button', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}