import 'dart:async';

import 'model_engine.dart';

/// Fallback engine with clearly-labeled canned responses so the APK demos the
/// full UX instantly, before a GGUF model has been loaded. The UI shows a
/// "demo engine" banner whenever this is active — it never pretends to be AI.
class DemoEngine implements ModelEngine {
  @override
  String get label => 'Demo engine (no model loaded)';

  @override
  bool get isLocalModel => false;

  @override
  double? get lastTokensPerSec => null;

  bool _cancelled = false;

  @override
  Future<String> generate({
    required String system,
    required String user,
    void Function(String textSoFar)? onUpdate,
    int maxTokens = 400,
    double temperature = 0.4,
  }) async {
    _cancelled = false;
    final full = _cannedResponse(system, user);
    // Emulate token streaming so screens exercise the same code path as the
    // real llama.cpp engine.
    final words = full.split(' ');
    final buffer = StringBuffer();
    for (final word in words) {
      if (_cancelled) break;
      buffer.write(buffer.isEmpty ? word : ' $word');
      onUpdate?.call(buffer.toString());
      await Future<void>.delayed(const Duration(milliseconds: 18));
    }
    return buffer.toString();
  }

  @override
  Future<void> cancel() async => _cancelled = true;

  String _cannedResponse(String system, String user) {
    final firstLine = user
        .trim()
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '')
        .trim();
    if (system.contains('MEDICINE_LENS')) {
      return '[DEMO OUTPUT — load a GGUF model for real on-device AI]\n\n'
          'Scanned text begins with: "$firstLine".\n\n'
          'What it is: This looks like a common over-the-counter medicine.\n'
          'Typical use: Fever and mild pain relief.\n'
          'Dosage: Follow only what is printed on the package.\n'
          'Warnings: Do not combine with other medicines containing the same '
          'ingredient. Keep away from children.\n\n'
          'Always confirm with a doctor or pharmacist before use.';
    }
    if (system.contains('TRIAGE')) {
      return '{"summary": "Demo: patient reports the described symptoms '
          '(${firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine}).", '
          '"possible_causes": ["Common viral illness", "Dehydration", '
          '"Needs in-person check"], '
          '"urgency": "amber", '
          '"advice": "Demo output only. Load a local GGUF model in Model '
          'Manager to get real on-device analysis. Ensure rest and fluids; '
          'monitor for worsening symptoms.", '
          '"referral_note": "DEMO — Patient described: $firstLine. '
          'Recommend PHC visit within 24h if symptoms persist."}';
    }
    return '[DEMO OUTPUT] Engine is running in demo mode. '
        'Load a GGUF model in Model Manager for real on-device inference. '
        'Your input was: $firstLine';
  }
}
