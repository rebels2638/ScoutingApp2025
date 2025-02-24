import 'package:flutter/material.dart';
import 'scouting.dart';
import 'widgets/telemetry_overlay.dart';
import 'widgets/telemetry_container.dart';
import '../services/telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TelemetryService().init();
  runApp(const MyApp());
}

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    required ThemeNotifier notifier,
    required Widget child,
    Key? key,
  }) : super(key: key, notifier: notifier, child: child);

  static ThemeNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    if (provider == null) {
      throw FlutterError('ThemeProvider not found in context');
    }
    return provider.notifier!;
  }
}

class ThemeNotifier extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode_enabled';
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final ThemeNotifier themeNotifier;
  bool telemetryVisible = false;
  bool _isInitialized = false;
  List<String> _telemetryData = [];

  @override
  void initState() {
    super.initState();
    themeNotifier = ThemeNotifier();
    themeNotifier.addListener(_handleThemeChange);
    _initializeApp();
    
    // Subscribe to telemetry events
    TelemetryService().eventStream.listen((event) {
      setState(() {
        _telemetryData.add(event.toString());
      });
    });
  }

  Future<void> _initializeApp() async {
    await themeNotifier._loadThemePreference();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    themeNotifier.dispose();
    super.dispose();
  }

  void _handleThemeChange() {
    setState(() {});
  }

  void toggleTelemetry(bool value) {
    setState(() {
      telemetryVisible = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ThemeProvider(
      notifier: themeNotifier,
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
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.black,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                elevation: 8,
              ),
              toggleButtonsTheme: ToggleButtonsThemeData(
                fillColor: Colors.blue.withOpacity(0.3),
                selectedColor: Colors.blue,
                color: Colors.grey,
                borderColor: Colors.grey.withOpacity(0.3),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                fillColor: Colors.black,
                filled: true,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
              ),
              dividerColor: Colors.grey[850],
              cardColor: Colors.black,
              dialogBackgroundColor: Colors.black,
              colorScheme: ColorScheme.dark(
                background: Colors.black,
                surface: Colors.black,
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                onBackground: Colors.white,
                onSurface: Colors.white,
                error: Colors.redAccent,
                onError: Colors.white,
                outline: Colors.grey.withOpacity(0.2),
              ),
              cardTheme: CardTheme(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                color: Colors.black,
                shadowColor: Colors.blue.withOpacity(0.2),
              ),
              dialogTheme: DialogTheme(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              listTileTheme: ListTileThemeData(
                selectedTileColor: Colors.blue.withOpacity(0.15),
                selectedColor: Colors.white,
                iconColor: Colors.white,
                textColor: Colors.white,
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue;
                  }
                  return Colors.grey.withOpacity(0.3);
                }),
                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Colors.blue,
                selectionColor: Colors.blue,
                selectionHandleColor: Colors.blue,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue;
                  }
                  return Colors.grey[400];
                }),
                trackColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.blue.withOpacity(0.3);
                  }
                  return Colors.grey.withOpacity(0.2);
                }),
              ),
              sliderTheme: SliderThemeData(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withOpacity(0.2),
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.grey[900],
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 8,
              ),
            ),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Stack(
              children: [
                _buildScoutingPage(),
                if (telemetryVisible)
                  SizedBox.expand(
                    child: Stack(
                      children: [
                        TelemetryContainer(
                          telemetryData: _telemetryData,
                          onClose: () {
                            setState(() {
                              telemetryVisible = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoutingPage() {
    return ScoutingPage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App 2025'),
      ),
      body: ScoutingPage(),
    );
  }
}