import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';

/// Model Manager: import any GGUF file and hot-swap the inference engine.
/// This is the "model-agnostic by design" screen — Qwen, Gemma, Granite,
/// MiniCPM, Sarvam all load the same way.
class ModelScreen extends StatefulWidget {
  const ModelScreen({super.key});

  @override
  State<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends State<ModelScreen> {
  bool _importing = false;

  Future<void> _pickModel() async {
    setState(() => _importing = true);
    try {
      final picked = await FilePicker.pickFile(type: FileType.any);
      final path = picked?.path;
      if (path == null) return;
      if (!path.toLowerCase().endsWith('.gguf')) {
        _snack('Pick a .gguf model file.');
        return;
      }
      await appState.useModel(path);
      _snack('Model loaded: ${path.split(Platform.pathSeparator).last}');
    } catch (e) {
      _snack('Import failed: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Manager')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final modelPath = appState.modelPath;
          final modelFile = modelPath != null ? File(modelPath) : null;
          final sizeMb = (modelFile != null && modelFile.existsSync())
              ? modelFile.lengthSync() / (1024 * 1024)
              : null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(
                    appState.engine.isLocalModel
                        ? Icons.memory
                        : Icons.smart_toy_outlined,
                    color: appState.engine.isLocalModel
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(appState.engine.label),
                  subtitle: Text(appState.engine.isLocalModel
                      ? 'On-device inference via llama.cpp'
                      '${sizeMb != null ? ' · ${sizeMb.toStringAsFixed(0)} MB' : ''}'
                      : 'Canned responses for UX demo — load a GGUF below'),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _importing ? null : _pickModel,
                icon: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.file_open),
                label: Text(
                    _importing ? 'Importing…' : 'Import GGUF model file'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: appState.engine.isLocalModel
                    ? appState.useDemoEngine
                    : null,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Switch back to demo engine'),
              ),
              const SizedBox(height: 20),
              Text('Device tiers (Q4 quantization)',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• 3–4 GB RAM phones → 0.3–1B models '
                          '(Qwen3 0.6B, Granite Nano, Gemma 1B)'),
                      SizedBox(height: 6),
                      Text('• 6–8 GB RAM phones → 1–2B models '
                          '(Gemma 2B, Sarvam-1 2B, MiniCPM)'),
                      SizedBox(height: 6),
                      Text('• Flagship (iQOO 15) → 2–4B models, GPU/NPU '
                          'accelerated'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Any GGUF works — the chat template ships inside the file and '
                'llama.cpp applies it. Download links are in the repo README. '
                'Copy the .gguf to the phone (or download on-device), then '
                'import it here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
