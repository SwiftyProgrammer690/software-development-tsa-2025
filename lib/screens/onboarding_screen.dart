// Written by 2152-901

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'home_screen.dart';

const _obBg   = Color(0xFF0E0C0A);
const _obText = Color(0xFFF0EBE3);
const _obSub  = Color(0xFF6B6560);

const _pages = [
  (Icons.sensors,Color(0xFFD4A843), 'Welcome.', 'An accessibility toolkit for people with vision or hearing disabilities.', null),
  (Icons.mic_rounded, Color(0xFF2DD4BF), 'Live captions', 'Speak naturally and watch your words appear on screen in real time.', 'Hearing'),
  (Icons.vibration_rounded, Color(0xFFFFB347), 'Smart alerts', 'Doorbells, alarms, and more felt through flashes and haptic patterns.', 'Hearing'),
  (Icons.document_scanner_rounded,Color(0xFF6EBF8B), 'Scene reader', 'Point your camera at any text and hear it read aloud instantly.', 'Vision'),
  (Icons.auto_stories_rounded, Color(0xFFFF7B5C), 'Spoken notes', 'Write notes and have them read back at your preferred speed.','Vision'),
  (Icons.check_rounded, Color(0xFFD4A843), 'Ready.','Everything runs on-device. No internet needed. Your data stays yours.', null),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => HomeScreen(
        highContrast: false,
        onToggleHighContrast: (_) {},
        colorBlindMode: ColorBlindMode.none,
        onColorBlindModeChanged: (_) {},
      ),
    ));
  }

  void _next() {
    HapticFeedback.lightImpact();
    _page < _pages.length - 1
        ? _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut)
        : _finish();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final (_, color, _, _, _) = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _obBg,
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 24, 0),
                child: isLast
                    ? const SizedBox(height: 36)
                    : GestureDetector(
                        onTap: _finish,
                        child: const Text('Skip',
                            style: TextStyle(fontSize: 14, color: _obSub)),
                      ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final (icon, col, title, sub, tag) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon with no container
                        Icon(icon, color: col, size: 44),
                        const SizedBox(height: 32),
                        // Tag
                        if (tag != null) ...[
                          Text(tag.toUpperCase(),
                              style: TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w700, color: col,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                        ],
                        // Title
                        Text(title, style: const TextStyle(
                            fontSize: 42, fontWeight: FontWeight.w800,
                            color: _obText, height: 1.0, letterSpacing: -1.5)),
                        const SizedBox(height: 18),
                        // Body
                        Text(sub, style: const TextStyle(
                            fontSize: 16, color: _obSub, height: 1.65)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Progress dots
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final (_, col, _, _, _) = _pages[i];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 20 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _page == i ? col : const Color(0xFF2A2520),
                    ),
                  );
                }),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(
                    isLast ? 'Get started' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.black, letterSpacing: -0.2),
                  )),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}