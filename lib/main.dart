// Written by 2152-901

// Import neccessary toolkits and services
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

// Initialize the app and check if the onboarding has been completed before
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(SenseBoardApp(showOnboarding: !onboardingDone));
}

enum ColorBlindMode { none, deuteranopia, protanopia, tritanopia }

// All colors for the app which is used by the other files as well
class SB {
  static bool highContrast = false;

  static Color get bg => highContrast ? Colors.black : const Color(0xFF0E0C0A);
  static Color get surface => highContrast ? const Color(0xFF111111) : const Color(0xFF1A1714);
  static Color get card => highContrast ? const Color(0xFF1A1A1A) : const Color(0xFF221F1B);
  static Color get border => highContrast ? const Color(0xFF444444) : const Color(0xFF2E2A25);
  static Color get gold => highContrast ? Colors.yellow : const Color(0xFFE8B84B);
  static Color get text => highContrast ? Colors.white : const Color(0xFFF2EDE6);
  static Color get textSub => highContrast ? const Color(0xFFCCCCCC) : const Color(0xFF8A8278);
  static Color get textMut => highContrast ? const Color(0xFF888888) : const Color(0xFF4A4540);

  // Colors that will always stay the same (hence the const)
  static const violet = Color(0xFF9B6DFF);
  static const teal = Color(0xFF2DD4BF);
  static const sage = Color(0xFF6EBF8B);
  static const coral = Color(0xFFFF7B5C);
}

// Sets up the main page and shows the onboarding if it hasn't been completed before
class SenseBoardApp extends StatefulWidget {
  final bool showOnboarding;
  const SenseBoardApp({super.key, required this.showOnboarding});

  @override
  State<SenseBoardApp> createState() => _SenseBoardAppState();
}

// Applies the color filters and makes sure the app is running smoothly
class _SenseBoardAppState extends State<SenseBoardApp> {
  bool _highContrast = false;
  ColorBlindMode _colorBlindMode = ColorBlindMode.none;

  static const Map<ColorBlindMode, List<double>> _matrices = {
    ColorBlindMode.deuteranopia: [0.625,0.375,0,0,0, 0.7,0.3,0,0,0, 0,0.3,0.7,0,0, 0,0,0,1,0],
    ColorBlindMode.protanopia: [0.567,0.433,0,0,0, 0.558,0.442,0,0,0, 0,0.242,0.758,0,0, 0,0,0,1,0],
    ColorBlindMode.tritanopia: [0.95,0.05,0,0,0, 0,0.433,0.567,0,0, 0,0.475,0.525,0,0, 0,0,0,1,0],
  };

  void _setColorBlindMode(ColorBlindMode mode) {
    setState(() => _colorBlindMode = mode);
  }

  void _setHighContrast(bool v) {
    SB.highContrast = v;
    setState(() => _highContrast = v);
  }

  @override
  Widget build(BuildContext context) {
    final matrix = _matrices[_colorBlindMode];
    return MaterialApp(
      title: 'SenseBoard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: SB.bg,
        colorScheme: ColorScheme.dark(
          primary: SB.gold,
          surface: SB.surface,
        ),
      ),
      builder: (_, child) => matrix == null
          ? child!
          : ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: child),
      home: widget.showOnboarding
          ? const OnboardingScreen()
          : HomeScreen(
              highContrast: _highContrast,
              onToggleHighContrast: _setHighContrast,
              colorBlindMode: _colorBlindMode,
              onColorBlindModeChanged: _setColorBlindMode,
            ),
    );
  }
}