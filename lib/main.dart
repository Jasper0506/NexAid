import 'package:flutter/material.dart';
import 'pages/splash_page.dart';

void main() {
  runApp(const NexAidApp());
}

class NexAidApp extends StatelessWidget {
  const NexAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexAid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}