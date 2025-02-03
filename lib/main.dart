import 'package:flutter/material.dart';
import 'scouting.dart';

void main() {
  runApp(const MyApp());
}

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    required ThemeNotifier notifier,
    required Widget child,
    Key? key,
  }) : super(key: key, notifier: notifier, child: child);

  static ThemeNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!.notifier!;
  }
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ThemeNotifier();
    _themeNotifier.addListener(_handleThemeChange);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  void _handleThemeChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeNotifier,
      child: Builder(
        builder: (context) {
          final isDarkMode = ThemeProvider.of(context).isDarkMode;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Scouting App 2025',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                elevation: 0,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.black,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
              ),
              toggleButtonsTheme: ToggleButtonsThemeData(
                fillColor: Colors.blue.withOpacity(0.3),
                selectedColor: Colors.blue,
                color: Colors.grey,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                fillColor: Colors.black,
                filled: true,
              ),
              dividerColor: Colors.grey[850],
              cardColor: Colors.black,
              dialogBackgroundColor: Colors.black,
              colorScheme: const ColorScheme.dark(
                background: Colors.black,
                surface: Colors.black,
                primary: Colors.blue,
                secondary: Colors.blueAccent,
              ),
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: ScoutingPage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App 2025'), // Updated AppBar title
      ),
      body: ScoutingPage(),
    );
  }
}