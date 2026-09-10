import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexAid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'NexAid'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _needHelp = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _toggleEmergencyStatus() {
    setState(() {
      _needHelp = !_needHelp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: Colors.blue,
                ),

                const SizedBox(height: 15),

                const Text(
                  'Welcome to NexAid',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Emergency assistance made simple.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Emergency Status Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _needHelp
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _needHelp ? Colors.red : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _needHelp
                            ? Icons.warning_rounded
                            : Icons.check_circle,
                        size: 60,
                        color: _needHelp ? Colors.red : Colors.green,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _needHelp ? 'NEED HELP' : 'SAFE',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _needHelp ? Colors.red : Colors.green,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _needHelp
                            ? 'Emergency assistance requested.'
                            : 'You are currently marked as safe.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 18),

                      ElevatedButton(
                        onPressed: _toggleEmergencyStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          _needHelp ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          _needHelp
                              ? 'CANCEL HELP'
                              : 'I NEED HELP',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Button Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$_counter',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _incrementCounter,
                  icon: const Icon(Icons.touch_app),
                  label: const Text('TEST BUTTON'),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Test',
        child: const Icon(Icons.add),
      ),
    );
  }
}