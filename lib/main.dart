import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for AssetBundle

// Top-level function for the isolate
int _computeFibonacci(int n) {
  if (n <= 1) return n;
  return _computeFibonacci(n - 1) + _computeFibonacci(n - 2);
}

Future<int> computeInIsolate(int n) async {
  final receivePort = ReceivePort();

  await Isolate.spawn((SendPort sendPort) {
    final result = _computeFibonacci(n);
    sendPort.send(result);
  }, receivePort.sendPort);

  return await receivePort.first as int;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIsolate',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.tealAccent,
          secondary: Colors.pinkAccent,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent[400],
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.tealAccent,
          inactiveTrackColor: Colors.grey[800],
          thumbColor: Colors.tealAccent,
          overlayColor: Colors.tealAccent.withOpacity(0.2),
        ),
      ),
      home: const FibonacciDemo(),
    );
  }
}

class FibonacciDemo extends StatefulWidget {
  const FibonacciDemo({super.key});

  @override
  State<FibonacciDemo> createState() => _FibonacciDemoState();
}

class _FibonacciDemoState extends State<FibonacciDemo> {
  int n = 30;
  int? _result;
  bool _isComputing = false;

  void _computeOnMainThread() {
    setState(() {
      _isComputing = true;
      _result = null;
    });

    final result = _computeFibonacci(n);

    setState(() {
      _result = result;
      _isComputing = false;
    });
  }

  Future<void> _computeInIsolate() async {
    setState(() {
      _isComputing = true;
      _result = null;
    });

    try {
      final result = await computeInIsolate(n);
      setState(() {
        _result = result;
        _isComputing = false;
      });
    } catch (e) {
      setState(() {
        _isComputing = false;
      });
      debugPrint('Isolate error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('FIsolate'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Result display at the top with moon.gif
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Text(
                                'Fibonacci($n)',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _result != null
                                  ? Text(
                                    '$_result',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : Text(
                                    _isComputing
                                        ? 'Calculating...'
                                        : 'Press a button to calculate',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      height: 100,
                      // child: Image.asset('moon.gif'),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Slider
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          'Select n value: $n',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: n.toDouble(),
                          min: 1,
                          max: 50,
                          divisions: 180,
                          label: n.toString(),
                          onChanged:
                              (value) => setState(() => n = value.round()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons stacked vertically
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isComputing ? null : _computeOnMainThread,
                        child: const Text('Run in Main Thread'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: const Text(
                          'When running on the Main Thread, the UI freezes for large input (n>40) of fibonacci number',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isComputing ? null : _computeInIsolate,
                        child: const Text('Run in Isolate'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: const Text(
                          'When running it on an Isolate, the main UI keeps working properly.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                // Loading indicator
                if (_isComputing) ...[
                  const SizedBox(height: 32),
                  LinearProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Colors.grey[800],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
