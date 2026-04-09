// Written by 2152-901

// Import all nessessary toolkits and services
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

// Initializes our "widget" for the screen to process
class SceneReaderScreen extends StatefulWidget {
  const SceneReaderScreen({super.key});

  @override
  State<SceneReaderScreen> createState() => _SceneReaderScreenState();
}

// Main code for the UI and functionality of this page
class _SceneReaderScreenState extends State<SceneReaderScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _tts = FlutterTts();

  bool _cameraReady = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _flashOn = false;
  String _recognizedText = '';
  String _statusMessage = 'Point camera at text and tap the button';

  @override
  void initState() {
    super.initState();
    _initCamera().then((_) => _startAutoCapture());
    _initTts();
  }

  // Logic for how to initialize the text-to-speech, set the language, speech rate, volume, and pitch, and also handle the start, completion, and cancel events to update the UI accordingly
  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
  }

  // Logic for how to initialize the camera, check for permissions, and handle errors if the camera isn't available or permission is denied
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _statusMessage = 'Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _statusMessage = 'No camera found');
      return;
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  // Logic for how to capture the image, process it with ML Kit, and read the text aloud with text-to-speech
  Future<void> _captureAndRead() async {
    if (_isProcessing || _cameraController == null || !_cameraReady) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Reading text...';
      _recognizedText = '';
    });

    if (_isSpeaking) await _tts.stop();

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognized = await _textRecognizer.processImage(inputImage);

      final text = recognized.text.trim();

      try { File(image.path).deleteSync(); } catch (_) {}

      if (text.isEmpty) {
        setState(() {
          _recognizedText = '';
          _statusMessage = 'No text found — try again';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _recognizedText = text;
        _statusMessage = 'Reading aloud...';
        _isProcessing = false;
      });

      await _tts.speak(text);
    } catch (e) {
      setState(() {
        _statusMessage = 'Something went wrong, try again';
        _isProcessing = false;
      });
    }
  }

  // Logic on how to toggle the flash on and off, and also update the button icon accordingly
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraReady) return;
    setState(() => _flashOn = !_flashOn);
    await _cameraController!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  // Logic on how to stop the text-to-speech if the user taps the button while it's speaking
  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() {
      _isSpeaking = false;
      _statusMessage = 'Tap the button to read again';
    });
  }

  // How to dispose or delete user entries
  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    _tts.stop();
    super.dispose();
  }

  Timer? _autoCaptureTimer;

  // Logic on how to start the automatic capture every 4 seconds if the camera is ready and not currently processing
  void _startAutoCapture() {
    _autoCaptureTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isProcessing && _cameraReady) {
        _captureAndRead();
      }
    });
  }

  // UI for this page
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0C0A),
        foregroundColor: Colors.white,
        title: const Text('Scene reader'),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleFlash,
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: _cameraReady && _cameraController != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: CameraPreview(_cameraController!),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: _statusMessage.contains('denied')
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt,
                                    color: Colors.white38, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _statusMessage,
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white),
                    ),
                  ),
          ),

          // Bottom panel
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Recognized text box
                  if (_recognizedText.isNotEmpty)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _recognizedText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stop speaking button
                      if (_isSpeaking)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: _stopSpeaking,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.stop,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),

                      // Main capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _captureAndRead,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing
                                ? Colors.grey
                                : scheme.primary,
                            boxShadow: _isProcessing
                                ? []
                                : [
                                    BoxShadow(
                                      color: scheme.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    )
                                  ],
                          ),
                          child: _isProcessing
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  Icons.document_scanner,
                                  color: Colors.white,
                                  size: 36,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}