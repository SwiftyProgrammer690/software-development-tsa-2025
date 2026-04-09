// Written by 2152-901

// Import all necessary services and toolkits
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/native_vibration.dart';

const _gold = Color(0xFFD4A843); // custom color for this file

// These are the default alarms that are set when first opening the app
const _defaults = [
  _Profile('Doorbell', Icons.doorbell, Color(0xFF9B6DFF), 2, 200),
  _Profile('Fire alarm', Icons.local_fire_department, Color(0xFFFF4444), 6, 80),
  _Profile('Phone ringing', Icons.phone, Color(0xFF2DD4BF), 3, 300),
  _Profile('Timer done', Icons.timer, Color(0xFF6EBF8B), 4, 150),
  _Profile('Someone calling', Icons.record_voice_over, Color(0xFFFFB347), 3, 250),
  _Profile('Emergency', Icons.warning_amber, Color(0xFFFF1744), 8, 60),
];

// These are the available icons the user can choose from when editing/creating a alarm
const _iconOptions = [
  Icons.doorbell, Icons.local_fire_department, Icons.phone, Icons.timer,
  Icons.record_voice_over, Icons.warning_amber, Icons.notifications,
  Icons.alarm, Icons.music_note, Icons.pets, Icons.directions_run, Icons.home,
];

// These are the available colors the user can choose from when editing/creating a alarm
const _colorOptions = [
  Color(0xFF9B6DFF), Color(0xFFFF4444), Color(0xFF2DD4BF), Color(0xFF6EBF8B),
  Color(0xFFFFB347), Color(0xFFFF1744), Color(0xFFD4A843), Color(0xFF4FC3F7),
  Color(0xFFFF7B5C), Color(0xFFE91E63), Color(0xFF00BCD4), Color(0xFF8BC34A),
];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

// This is the main code for this page
class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 80));

  List<_Profile> _profiles = List.from(_defaults);
  bool _hapticsOn = true;
  bool _flashOn   = true;
  bool _busy      = false;
  Color _flashColor = Colors.transparent;
  Set<String> _favs = {};
  String? _active;

  @override
  void initState() { super.initState(); _load(); }

  // Logic for loading and saving the profiles, as well as triggering the alerts and opening the editor
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _favs      = p.getStringList('alert_favs')?.toSet() ?? {};
    _hapticsOn = p.getBool('alert_haptics') ?? true;
    _flashOn   = p.getBool('alert_flash') ?? true;
    final raw  = p.getStringList('alert_profiles');
    if (raw != null) {
      _profiles = raw.map((s) => _Profile.fromJson(jsonDecode(s))).toList();
    }
    setState(() {});
  }

  // Logic for saving the profiles, favorites, and settings to shared preferences
  Future<void> _saveProfiles() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('alert_profiles',
        _profiles.map((p) => jsonEncode(p.toJson())).toList());
    await p.setStringList('alert_favs', _favs.toList());
    await p.setBool('alert_haptics', _hapticsOn);
    await p.setBool('alert_flash', _flashOn);
  }

  // This is the main logic for triggering an alert profile, which includes vibrating and flashing the screen according to the profile settings
  Future<void> _trigger(_Profile profile) async {
    if (_busy) return;
    setState(() { _busy = true; _active = profile.name; _flashColor = profile.color; });

    if (_hapticsOn) {
      NativeVibration.vibratePulses(
          count: profile.pulseCount, durationMs: 120, gapMs: profile.pulseGap);
    }

    if (_flashOn) {
      for (int i = 0; i < profile.pulseCount && mounted; i++) {
        await _flash.forward(from: 0);
        await _flash.reverse();
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() { _busy = false; _active = null; });
  }

  // Setting a favorite
  void _toggleFav(String name) {
    setState(() => _favs.contains(name) ? _favs.remove(name) : _favs.add(name));
    _saveProfiles();
  }

  // Opening the alarm editor
  void _openEditor(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditor(
        profile: _profiles[index],
        onSave: (updated) {
          setState(() => _profiles[index] = updated);
          _saveProfiles();
        },
      ),
    );
  }

  @override
  void dispose() { _flash.dispose(); super.dispose(); }

  // Main UI for this page
  @override
  Widget build(BuildContext context) {
    final sub = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    final sorted = _profiles.asMap().entries.toList()
      ..sort((a, b) => (_favs.contains(b.value.name) ? 1 : 0) - (_favs.contains(a.value.name) ? 1 : 0));

    return AnimatedBuilder(
      animation: _flash,
      builder: (context, child) => Stack(fit: StackFit.expand, children: [
        child!,
        if (_flashOn && _flash.value > 0)
          Positioned.fill(child: IgnorePointer(
            child: Container(color: _flashColor.withOpacity(_flash.value * 0.8)),
          )),
      ]),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart alerts'),
          actions: [
            GestureDetector(
              onTap: () { setState(() => _hapticsOn = !_hapticsOn); _saveProfiles(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.vibration, color: _hapticsOn ? _gold : sub, size: 20),
              ),
            ),
            GestureDetector(
              onTap: () { setState(() => _flashOn = !_flashOn); _saveProfiles(); },
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 20),
                child: Icon(Icons.flash_on, color: _flashOn ? _gold : sub, size: 20),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text('Tap to test · swipe to edit',
                  style: TextStyle(fontSize: 12, color: sub)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final index = sorted[i].key;
                  final p = sorted[i].value;
                  final isActive = _active == p.name;
                  final isFav = _favs.contains(p.name);
                  return Dismissible(
                    key: ValueKey(p.name),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      _openEditor(index);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.edit_outlined, color: sub, size: 18),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _trigger(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 3, height: 44,
                            decoration: BoxDecoration(
                              color: isActive ? p.color : p.color.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(p.icon,
                              color: isActive ? p.color : p.color.withOpacity(0.7), size: 22),
                          const SizedBox(width: 14),
                          Expanded(child: Text(p.name,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500,
                                  color: isActive ? p.color : Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.2))),
                          GestureDetector(
                            onTap: () => _toggleFav(p.name),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: isFav ? _gold : sub, size: 18),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  final _Profile profile;
  final ValueChanged<_Profile> onSave;
  const _ProfileEditor({required this.profile, required this.onSave});
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

// This is the main code for the alarm editor and its logic
class _ProfileEditorState extends State<_ProfileEditor> {
  late final _nameCtrl = TextEditingController(text: widget.profile.name);
  late IconData _icon       = widget.profile.icon;
  late Color    _color      = widget.profile.color;
  late double   _pulseCount = widget.profile.pulseCount.toDouble();
  late double   _pulseGap   = widget.profile.pulseGap.toDouble();

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  // Main UI for the alarm editor page
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sub = scheme.onSurface.withOpacity(0.4);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 32, height: 3, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: sub.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)))),

          // Name
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 16, color: scheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: sub),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: sub.withOpacity(0.2))),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _color)),
            ),
          ),

          const SizedBox(height: 24),

          // Color picker
          Text('Color', style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10,
            children: _colorOptions.map((c) => GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _color == c
                      ? Border.all(color: scheme.onSurface, width: 2)
                      : null,
                ),
              ),
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Icon picker
          Text('Icon', style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10,
            children: _iconOptions.map((ic) => GestureDetector(
              onTap: () => setState(() => _icon = ic),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _icon == ic ? _color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _icon == ic ? _color : sub.withOpacity(0.2)),
                ),
                child: Icon(ic, color: _icon == ic ? _color : sub, size: 20),
              ),
            )).toList(),
          ),

          const SizedBox(height: 24),

          // Pulse count
          Row(children: [
            Text('Pulses', style: TextStyle(fontSize: 13, color: sub)),
            const Spacer(),
            Text('${_pulseCount.round()}',
                style: TextStyle(fontSize: 13, color: scheme.onSurface)),
          ]),
          Slider(
            value: _pulseCount, min: 1, max: 10, divisions: 9,
            activeColor: _color,
            onChanged: (v) => setState(() => _pulseCount = v),
          ),

          // Pulse speed
          Row(children: [
            Text('Speed', style: TextStyle(fontSize: 13, color: sub)),
            const Spacer(),
            Text(_pulseGap < 100 ? 'Fast' : _pulseGap < 250 ? 'Medium' : 'Slow',
                style: TextStyle(fontSize: 13, color: scheme.onSurface)),
          ]),
          Slider(
            value: _pulseGap, min: 50, max: 400, divisions: 7,
            activeColor: _color,
            onChanged: (v) => setState(() => _pulseGap = v),
          ),

          const SizedBox(height: 8),

          // Save the alarm
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave(_Profile(
                  _nameCtrl.text.trim().isEmpty ? widget.profile.name : _nameCtrl.text.trim(),
                  _icon, _color,
                  _pulseCount.round(),
                  _pulseGap.round(),
                ));
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _color, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// Displaying the new or edited alarm
class _Profile {
  final String name;
  final IconData icon;
  final Color color;
  final int pulseCount, pulseGap;
  const _Profile(this.name, this.icon, this.color, this.pulseCount, this.pulseGap);

  _Profile copyWith({String? name, IconData? icon, Color? color, int? pulseCount, int? pulseGap}) =>
      _Profile(name ?? this.name, icon ?? this.icon, color ?? this.color,
          pulseCount ?? this.pulseCount, pulseGap ?? this.pulseGap);

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': _iconOptions.indexOf(icon),
    'color': color.value,
    'pulseCount': pulseCount,
    'pulseGap': pulseGap,
  };

  factory _Profile.fromJson(Map<String, dynamic> j) => _Profile(
    j['name'],
    _iconOptions[j['icon'] as int],
    Color(j['color'] as int),
    j['pulseCount'] as int,
    j['pulseGap'] as int,
  );
}