import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  Function(bool)? onPlayingChanged;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.1);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        onPlayingChanged?.call(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        onPlayingChanged?.call(false);
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        onPlayingChanged?.call(false);
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        onPlayingChanged?.call(false);
      });
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    try {
      await stop();
      // Clean markdown tags for natural speech
      final cleanText = text
          .replaceAll(RegExp(r'#+\s*'), '')
          .replaceAll(RegExp(r'\*\*|\*|`|\[|\]'), '')
          .replaceAll(RegExp(r'\(http[^\)]+\)'), '')
          .replaceAll(RegExp(r'>\s*'), '');

      if (cleanText.trim().isNotEmpty) {
        _isPlaying = true;
        onPlayingChanged?.call(true);
        await _flutterTts.speak(cleanText);
      }
    } catch (_) {
      _isPlaying = false;
      onPlayingChanged?.call(false);
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isPlaying = false;
    onPlayingChanged?.call(false);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
