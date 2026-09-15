import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over the platform text-to-speech engine. Voice output is a
/// first-class interaction in Sahayak: answers are spoken for low-literacy
/// users, in the language selected on the home screen.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, String language) async {
    await _tts.stop();
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}

final TtsService tts = TtsService();
