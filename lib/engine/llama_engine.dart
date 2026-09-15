import 'dart:async';
import 'dart:io';

import 'package:fllama/fllama.dart';

import 'model_engine.dart';

/// Real on-device inference via llama.cpp (through the fllama FFI binding).
/// Model-agnostic by design: anything published as a GGUF file — Qwen, Gemma,
/// Granite Nano, MiniCPM, Sarvam, SmolLM — loads here unchanged, because the
/// chat template ships inside the GGUF metadata and llama.cpp applies it.
class LlamaEngine implements ModelEngine {
  LlamaEngine(this.modelPath);

  final String modelPath;
  int? _requestId;
  double? _lastTokensPerSec;

  @override
  String get label => modelPath.split(Platform.pathSeparator).last;

  @override
  bool get isLocalModel => true;

  @override
  double? get lastTokensPerSec => _lastTokensPerSec;

  @override
  Future<String> generate({
    required String system,
    required String user,
    void Function(String textSoFar)? onUpdate,
    int maxTokens = 400,
    double temperature = 0.4,
  }) async {
    final completer = Completer<String>();
    final stopwatch = Stopwatch()..start();

    final request = OpenAiRequest(
      modelPath: modelPath,
      messages: [
        Message(Role.system, system),
        Message(Role.user, user),
      ],
      maxTokens: maxTokens,
      temperature: temperature,
      topP: 0.95,
      contextSize: 2048,
      // llama.cpp ignores this where unsupported; on capable devices it
      // offloads to GPU. CPU path always works, which is the low-end story.
      numGpuLayers: 99,
      frequencyPenalty: 0.0,
      presencePenalty: 0.0,
    );

    _requestId = await fllamaChat(request, (response, responseJson, done) {
      onUpdate?.call(response);
      if (done && !completer.isCompleted) {
        stopwatch.stop();
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        if (seconds > 0 && response.isNotEmpty) {
          // ~4 chars/token is a fair cross-model approximation for a
          // hackathon dashboard; swap for fllamaTokenize for exact counts.
          _lastTokensPerSec = (response.length / 4) / seconds;
        }
        completer.complete(response);
      }
    });

    return completer.future;
  }

  @override
  Future<void> cancel() async {
    final id = _requestId;
    if (id != null) {
      fllamaCancelInference(id);
    }
  }
}
