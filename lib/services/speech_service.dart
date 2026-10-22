import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  double _soundLevel = 0.0;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
  double get soundLevel => _soundLevel;

  Function(bool isListening)? onListeningStateChanged;
  Function(double level)? onSoundLevelChanged;

  Future<bool> init() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String recognizedWords) onResult,
  }) async {
    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return;
    }

    try {
      _isListening = true;
      onListeningStateChanged?.call(true);

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        onSoundLevelChange: (level) {
          _soundLevel = level;
          onSoundLevelChanged?.call(level);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _isListening = false;
    onListeningStateChanged?.call(false);
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
    _isListening = false;
    onListeningStateChanged?.call(false);
  }
}
