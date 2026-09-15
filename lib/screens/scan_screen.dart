import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../prompts.dart';
import '../services/tts_service.dart';

/// Medicine Lens: camera → on-device OCR (ML Kit) → local LLM explanation →
/// spoken answer. The entire chain runs offline.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _ocrController = TextEditingController();

  String? _imagePath;
  String _response = '';
  bool _ocrBusy = false;
  bool _generating = false;

  @override
  void dispose() {
    _recognizer.close();
    _ocrController.dispose();
    tts.stop();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    final XFile? photo =
        await _picker.pickImage(source: source, maxWidth: 1600);
    if (photo == null) return;
    setState(() {
      _imagePath = photo.path;
      _ocrBusy = true;
      _response = '';
    });
    try {
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(photo.path));
      _ocrController.text = recognized.text.trim();
      if (_ocrController.text.isEmpty) {
        _ocrController.text = '';
        _snack('No text found — try a closer, well-lit shot of the label.');
      }
    } catch (e) {
      _snack('OCR failed: $e');
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  Future<void> _explain() async {
    final ocrText = _ocrController.text.trim();
    if (ocrText.isEmpty) {
      _snack('Scan a medicine label first (or type the text).');
      return;
    }
    setState(() {
      _generating = true;
      _response = '';
    });
    try {
      final result = await appState.engine.generate(
        system: Prompts.fill(appState.medLensPrompt,
            language: appState.language),
        user: ocrText,
        onUpdate: (textSoFar) {
          if (mounted) setState(() => _response = textSoFar);
        },
      );
      appState.recordRun(result);
      if (mounted) setState(() => _response = result);
    } catch (e) {
      _snack('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
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
      appBar: AppBar(title: const Text('Medicine Lens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _ocrBusy ? null : () => _capture(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _ocrBusy ? null : () => _capture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_imagePath!), height: 160,
                  fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          Text('Scanned text (editable)',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          if (_ocrBusy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextField(
              controller: _ocrController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Text from the medicine label appears here…',
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generating ? null : _explain,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? 'Thinking on-device…' : 'Explain'),
          ),
          if (_response.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_response),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () =>
                              tts.speak(_response, appState.language),
                          icon: const Icon(Icons.volume_up),
                          tooltip: 'Speak',
                        ),
                        IconButton(
                          onPressed: tts.stop,
                          icon: const Icon(Icons.stop_circle_outlined),
                          tooltip: 'Stop',
                        ),
                        const Spacer(),
                        if (appState.engine.lastTokensPerSec != null)
                          Text(
                            '${appState.engine.lastTokensPerSec!.toStringAsFixed(1)} tok/s',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
