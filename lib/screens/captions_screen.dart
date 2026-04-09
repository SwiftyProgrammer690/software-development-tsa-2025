// Written by 2152-901

// Import neccesary toolkits and services
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// This code makes our live captioning screen show up
class CaptionsScreen extends StatefulWidget {
  const CaptionsScreen({super.key});

  @override
  State<CaptionsScreen> createState() => _CaptionsScreenState();
}

// This code is the live updated view that constantly runs a loop to check for text and reads it aloud using the TTS service
class _CaptionsScreenState extends State<CaptionsScreen> {
  final SpeechToText _speech = SpeechToText();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isAvailable = false;
  String _currentWords = '';
  final List<String> _transcript = [];
  double _confidence = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
  // Logic for handling whether or not to start auto recording and when to stop recording
  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_currentWords.isNotEmpty) {
            setState(() {
              _transcript.add(_currentWords);
              _currentWords = '';
            });
          }
          if (_isListening) _startListening();
        }
      },
    );
    setState(() => _isAvailable = available);
  }

  // This is the main loop that listens for speech and updates the transcript in real time and also handles confidence rating and auto scrolling to the bottom of the transcript
  void _startListening() {
    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() {
          _currentWords = result.recognizedWords;
          if (result.hasConfidenceRating) {
            _confidence = result.confidence;
          }
        });
        _scrollToBottom();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10),
      localeId: 'en_US',
      cancelOnError: false,
      partialResults: true,
    );
  }

  // This is the function that toggles the listening state on and off when the mic button is pressed and also adds the current words to the transcript if there are any when stopping
  void _toggleListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        if (_currentWords.isNotEmpty) {
          _transcript.add(_currentWords);
          _currentWords = '';
        }
      });
    } else {
      setState(() => _isListening = true);
      _startListening();
    }
  }

  // This deletes or clears all the transcirpts if the uesr presses the button
  void _clearTranscript() {
    setState(() {
      _transcript.clear();
      _currentWords = '';
    });
  }

  // This is the function that auto scrolls to the bottom of the transcript when new words are added so that the user can always see the most recent captions without having to manually scroll down
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // This is the main build of our UI and is what makes it look good
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHighContrast = scheme.surface == Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live captions'),
        actions: [
          if (_transcript.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
              onPressed: _clearTranscript,
            ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: _isListening
                ? Colors.red.withOpacity(0.1)
                : scheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _isListening
                      ? 'Listening...'
                      : _isAvailable
                          ? 'Tap the mic to start'
                          : 'Microphone unavailable',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isListening ? Colors.red : scheme.onSurface.withOpacity(0.6),
                    fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                // This code displays the confidence rating of the TTS service
                if (_isListening && _confidence > 0)
                  Text(
                    '${(_confidence * 100).round()}% confidence',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          // This is the UI for the transcript area
          Expanded(
            child: _transcript.isEmpty && _currentWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none,
                          size: 64,
                          color: scheme.onSurface.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Captions will appear here',
                          style: TextStyle(
                            fontSize: 16,
                            color: scheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      ..._transcript.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: isHighContrast ? 22 : 20,
                              height: 1.5,
                              color: scheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                      if (_currentWords.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: scheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _currentWords,
                            style: TextStyle(
                              fontSize: isHighContrast ? 22 : 20,
                              height: 1.5,
                              color: scheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // This is the UI for the mic button
          Padding(
            padding: const EdgeInsets.all(28),
            child: GestureDetector(
              onTap: _isAvailable ? _toggleListening : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.red
                      : _isAvailable
                          ? scheme.primary
                          : Colors.grey,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
