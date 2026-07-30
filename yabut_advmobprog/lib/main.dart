import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// This is the entry point of the application where the ChangeNotifierProvider
// is wrappedso that the theme can be accessed in the other part of the application.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

// This is the ThemeModel which manages the application's theme state using 
// ChangeNotifier so widgets can listen for changes.
class ThemeModel extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// This is the root widget of the application where it Listens to ThemeModel 
// and updates the entire app theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Provider Example",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const CounterScreen(),
    );
  }
}

// This is the 1st Screen which Demonstrates ephemeral state using setState().
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ephemeral State Example"),
        // This is the added button for the 1st Screen to access the 2nd Screen(Theme Screen)
        // to toggle the dark and light mode.
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeScreen(),
                  ),
              );
            },
          ),]
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "You have pushed the button this many times:",
            ),
            Text(
              "$_counter",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// This is the 2nd Screen which Demonstrates app state using Provider so that changing 
// the switch will update the theme across the whole app.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Theme Screen"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
            children: [
              const SizedBox(width: 30),
              Icon(
                themeModel.isDark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                size: 25,
              ),
              const SizedBox(width: 30),
              Text(
                themeModel.isDark
                    ? "Dark Mode Enabled"
                    : "Light Mode Enabled",
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 30),
              Switch(
                value: themeModel.isDark,
                onChanged: (_) {
                  themeModel.toggleTheme();
                },
              ),
            ],
            ),
          ],
        ),
      ),
    );
  }
}