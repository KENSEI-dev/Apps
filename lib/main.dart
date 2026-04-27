import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Auth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/home': (context) => const HomeScreen(),
    //'/icon-test': (context) => const IconTestScreen(),  // ADD THIS
},
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() async {
    final isAuth = await AuthService.isAuthenticated();
    if (mounted) {
      if (isAuth) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
/*
class IconTestScreen extends StatelessWidget {
  const IconTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Test'),
      ),
      body: const Center(
        child: Icon(
          Icons.verified_user,
          size: 64,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
*/