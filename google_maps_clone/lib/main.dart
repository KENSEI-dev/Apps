import 'package:flutter/material.dart';
import 'package:google_maps_clone/constants.dart';
import 'package:google_maps_clone/live_tracking_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Live Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: const LiveTrackingPage(),
    );
  }
}