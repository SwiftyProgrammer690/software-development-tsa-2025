// Written by 2152-901

// Import neccessary toolkits and services
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'captions_screen.dart';
import 'alerts_screen.dart';
import 'scene_reader_screen.dart';
import 'notes_screen.dart';
import 'about_screen.dart';

// Colors for the home screen, with high contrast variants
const _bg     = Color(0xFF0E0C0A);
const _text   = Color(0xFFF0EBE3);
const _sub    = Color(0xFF6B6560);
const _gold   = Color(0xFFD4A843);
const _dim    = Color(0xFF2A2520);
const _teal   = Color(0xFF2DD4BF);
const _sage   = Color(0xFF6EBF8B);
const _coral  = Color(0xFFFF7B5C);
const _amber  = Color(0xFFFFB347);

// This is our main home screen, showing the 4 core features and access to settings/about pages
class HomeScreen extends StatefulWidget {
  final bool highContrast;
  final ValueChanged<bool> onToggleHighContrast;
  final ColorBlindMode colorBlindMode;
  final ValueChanged<ColorBlindMode> onColorBlindModeChanged;

  // This code toggles high contrast and color blind modes
  const HomeScreen({super.key, required this.highContrast,
      required this.onToggleHighContrast, required this.colorBlindMode,
      required this.onColorBlindModeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  // Get the background colors based on the current high contrast setting
  Color get bg => widget.highContrast ? Colors.black : _bg;
  Color get text => widget.highContrast ? Colors.white : _text;
  Color get sub => widget.highContrast ? Colors.white60 : _sub;
  Color get gold => widget.highContrast ? Colors.yellow : _gold;

  // Shows main tiles and views for the user to use
  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Live captions', 'Mic',_teal,  Icons.mic_rounded, const CaptionsScreen()),
      ('Smart alerts', 'Haptic', _amber, Icons.vibration_rounded, const AlertsScreen()),
      ('Scene reader', 'OCR',_sage,  Icons.document_scanner_rounded, const SceneReaderScreen()),
      ('Spoken notes', 'TTS',_coral, Icons.auto_stories_rounded, const NotesScreen()),
    ];

    // This AnnotatedRegion sets the status bar icons to light mode for better visibility on dark backgrounds
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // We use scaffolds to set up the basic visual layout of the app with a column for the header and tiles
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 0),
                child: Row(children: [
                  Icon(Icons.sensors, color: gold, size: 18),
                  const SizedBox(width: 7),
                  Text('SenseBoard', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: text, letterSpacing: 0.2,
                  )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen())),
                    child: Icon(Icons.book_outlined, color: sub, size: 20),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () { HapticFeedback.mediumImpact(); _openSettings(context); },
                    child: Icon(Icons.tune_rounded, color: sub, size: 20),
                  ),
                ]),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Hear more.\nSee more.',
                  style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w800,
                    color: text, height: 1.05, letterSpacing: -1.5,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // This is the code for our entry/startup animation
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tiles.length,
                  itemBuilder: (context, i) {
                    final delay = i * 0.15;
                    final a = CurvedAnimation(parent: _anim, curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeOut));
                    final (label, tag, color, icon, screen) = tiles[i];
                    return AnimatedBuilder(
                      animation: a,
                      builder: (_, child) => Opacity(
                        opacity: a.value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - a.value)), child: child),
                      ),
                      child: _Row(label: label, tag: tag, color: color,
                      icon: icon, screen: screen, sub: sub, text: text),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This function handles opening the screen for user settings
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        highContrast: widget.highContrast,
        onToggleHighContrast: widget.onToggleHighContrast,
        colorBlindMode: widget.colorBlindMode,
        onColorBlindModeChanged: widget.onColorBlindModeChanged,
        bg: bg, text: text, sub: sub, gold: gold,
      ),
    );
  }
}

// This class includes our code for the individual rows/tiles on the home screen, including the tap animations and navigation to the respective feature screens
class _Row extends StatefulWidget {
  final String label, tag;
  final Color color, sub, text;
  final IconData icon;
  final Widget screen;
  const _Row({required this.label, required this.tag, required this.color, required this.icon, required this.screen, required this.sub, required this.text});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _s = Tween(begin: 1.0, end: 0.97).animate(_c);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  // Handles animations and the navigation when a user hits on a tile
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => widget.screen));
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Container(width: 3, height: 44,
                decoration: BoxDecoration(color: widget.color,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 16),
            Icon(widget.icon, color: widget.color, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: widget.text, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(widget.tag, style: TextStyle(fontSize: 12, color: widget.sub)),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: widget.sub, size: 18),
          ]),
        ),
      ),
    );
  }
}

// This class includes our code for the settings page which allows users to toggle high contrast mode and select their color blind mode with a preview of the changes in real time

class _SettingsSheet extends StatefulWidget {
  final bool highContrast;
  final ValueChanged<bool> onToggleHighContrast;
  final ColorBlindMode colorBlindMode;
  final ValueChanged<ColorBlindMode> onColorBlindModeChanged;
  final Color bg, text, sub, gold;
  const _SettingsSheet({required this.highContrast, required this.onToggleHighContrast, required this.colorBlindMode, required this.onColorBlindModeChanged, required this.bg, required this.text, required this.sub, required this.gold});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

// This manages the "preview" state of the settings when they aren't applied so the user can play around
class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _hc;
  late ColorBlindMode _cbm;

  @override
  void initState() { super.initState(); _hc = widget.highContrast; _cbm = widget.colorBlindMode; }

  // This builds the settings page with the options for high contrast and color blind modes, and updates the preview in real time as users toggle the settings
  @override
  Widget build(BuildContext context) {
    final modes = {
      ColorBlindMode.none: 'Normal',
      ColorBlindMode.deuteranopia: 'Deuteranopia',
      ColorBlindMode.protanopia: 'Protanopia',
      ColorBlindMode.tritanopia: 'Tritanopia',
    };

    // This container includes the main UI and features of the settings screen
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: widget.bg == Colors.black ? const Color(0xFF111111) : _dim,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 32, height: 3,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: widget.sub.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2)))),
          Text('Settings', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700, color: widget.text)),
          const SizedBox(height: 24),
          Row(children: [
            Text('High contrast', style: TextStyle(fontSize: 15, color: widget.text)),
            const Spacer(),
            Switch(value: _hc, activeColor: widget.gold, onChanged: (v) {
              setState(() => _hc = v);
              widget.onToggleHighContrast(v);
            }),
          ]),
          const SizedBox(height: 20),
          Text('Color vision', style: TextStyle(fontSize: 13, color: widget.sub)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: modes.entries.map((e) {
            final sel = _cbm == e.key;
            return GestureDetector(
              onTap: () {
                setState(() => _cbm = e.key);
                widget.onColorBlindModeChanged(e.key);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? widget.gold.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: sel ? widget.gold : widget.sub.withOpacity(0.3)),
                ),
                child: Text(e.value, style: TextStyle(fontSize: 13,
                    color: sel ? widget.gold : widget.sub,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }
}