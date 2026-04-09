// Written by 2152-901

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About SenseBoard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8B84B).withOpacity(0.12),
                      border: Border.all(
                        color: const Color(0xFFE8B84B).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.sensors,
                        size: 40, color: Color(0xFFE8B84B)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SenseBoard',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _Section(
              title: 'Problem statement',
              child: Text(
                'Over 1.5 billion people worldwide live with hearing loss, and more than 2.2 billion have some form of vision impairment. Despite this, most digital tools are designed for users without disabilities, creating significant barriers in everyday tasks like reading signs, following conversations, and receiving important alerts.\n\nSenseBoard addresses these barres by using on-device AI, TTS, transcription, and more to provide real-time assistance even while being fully offline.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: scheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _Section(
              title: 'How it helps',
              child: Column(
                children: [
                  _HelpRow(
                    icon: Icons.mic,
                    color: const Color(0xFF7C4DFF),
                    title: 'Live captions',
                    description:
                        'Converts speech to text in real time, helping deaf and hard-of-hearing users follow conversations without relying on others.',
                  ),
                  _HelpRow(
                    icon: Icons.vibration,
                    color: const Color(0xFF00BCD4),
                    title: 'Smart alerts',
                    description:
                        'Translates audio alerts (doorbells, alarms) into haptic patterns and visual flashes so deaf users never miss important signals.',
                  ),
                  _HelpRow(
                    icon: Icons.camera_alt,
                    color: const Color(0xFF4CAF50),
                    title: 'Scene reader',
                    description:
                        'Uses on-device OCR to extract and read text from the camera, helping blind and low-vision users access printed information independently.',
                  ),
                  _HelpRow(
                    icon: Icons.notes,
                    color: const Color(0xFFFF7043),
                    title: 'Spoken notes',
                    description:
                        'Allows blind users to write notes and have them read back with natural text-to-speech, adjustable to their preferred speed.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _Section(
              title: 'Technical details',
              child: Column(
                children: [
                  _TechRow(label: 'Platform', value: 'Android (Flutter)'),
                  _TechRow(label: 'Speech recognition', value: 'speech_to_text (Web Speech API)'),
                  _TechRow(label: 'Text-to-speech', value: 'flutter_tts (on-device)'),
                  _TechRow(label: 'OCR engine', value: 'Google MLKit (on-device, offline)'),
                  _TechRow(label: 'Haptics', value: 'Custom vibration patterns'),
                  _TechRow(label: 'Data storage', value: 'Local only, never uploaded'),
                  _TechRow(label: 'Internet required', value: 'No, this works fully offline'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _Section(
              title: 'TSA Software Development',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Built for the TSA High School Software Development event. Theme: Develop a software program that removes barriers and increases accessibility for people with vision or hearing disabilities.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF7C4DFF).withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                'Made with Flutter',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withOpacity(0.4),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _HelpRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final String label;
  final String value;
  const _TechRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}