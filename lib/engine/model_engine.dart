/// Engine abstraction: every text model (llama.cpp GGUF, demo stub, or a
/// future ONNX/NPU backend) sits behind this interface. Screens only talk to
/// [ModelEngine], so swapping models is a config change, not a refactor.
abstract class ModelEngine {
  /// Short human-readable label shown in the UI, e.g. "qwen3-0.6b-q4.gguf".
  String get label;

  /// True when this engine runs a real local model (vs. canned demo output).
  bool get isLocalModel;

  /// Approximate decode speed of the most recent run, tokens/second.
  double? get lastTokensPerSec;

  /// Runs one system+user turn. [onUpdate] receives the cumulative response
  /// text as it streams. Returns the final response.
  Future<String> generate({
    required String system,
    required String user,
    void Function(String textSoFar)? onUpdate,
    int maxTokens = 400,
    double temperature = 0.4,
  });

  /// Cancels an in-flight generation, if any.
  Future<void> cancel();
}
