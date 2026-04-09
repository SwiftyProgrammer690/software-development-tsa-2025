// Written by 2152-901

// Import services package for haptic feedback
import 'package:flutter/services.dart';

// Service to handle native vibration functionality
class NativeVibration {
  static const _channel = MethodChannel('com.example.senseboard/vibration');

  static Future<void> vibratePulses({
    required int count,
    required int durationMs,
    required int gapMs,
  }) async {
    try {
      await _channel.invokeMethod('vibratePulses', {
        'count': count,
        'duration': durationMs,
        'gap': gapMs,
      });
    } catch (_) {
      // Fallback if the system does not support it
      for (int i = 0; i < count; i++) {
        await HapticFeedback.vibrate();
        await Future.delayed(Duration(milliseconds: gapMs));
      }
    }
  }
}