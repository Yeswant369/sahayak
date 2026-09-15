import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../app_state.dart';
import '../prompts.dart';
import '../services/tts_service.dart';

/// Voice Triage: speak symptoms → on-device speech-to-text → local LLM →
/// structured screening result (urgency, advice, referral note) → spoken back.
class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final SpeechToText _stt = SpeechToText();
  final _transcriptController = TextEditingController();

  bool _sttAvailable = false;
  bool _listening = false;
  bool _generating = false;
  Map<String, dynamic>? _result;
  String _raw = '';

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    try {
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (e) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _sttAvailable = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stt.stop();
    _transcriptController.dispose();
    tts.stop();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _stt.listen(
      onResult: (result) {
        _transcriptController.text = result.recognizedWords;
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        localeId: appState.language.replaceAll('-', '_'),
      ),
    );
  }

  Future<void> _analyze() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      _snack('Describe the symptoms first — by voice or typing.');
      return;
    }
    setState(() {
      _generating = true;
      _result = null;
      _raw = '';
    });
    try {
      final response = await appState.engine.generate(
        system:
            Prompts.fill(appState.triagePrompt, language: appState.language),
        user: transcript,
        temperature: 0.2,
      );
      appState.recordRun(response);
      setState(() {
        _raw = response;
        _result = _extractJson(response);
      });
    } catch (e) {
      _snack('Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Small models sometimes wrap JSON in prose; pull out the outermost object.
  Map<String, dynamic>? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _urgencyColor(String urgency) => switch (urgency.toLowerCase()) {
        'red' => Colors.red,
        'amber' => Colors.orange,
        _ => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Triage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: _sttAvailable ? _toggleListen : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _listening ? Colors.red : null,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16),
                  ),
                  icon: Icon(_listening ? Icons.stop : Icons.mic),
                  label: Text(_listening ? 'Stop' : 'Describe symptoms'),
                ),
                if (!_sttAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Speech recognition unavailable — type below instead.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _transcriptController,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Patient says… (editable)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generating ? null : _analyze,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.medical_information_outlined),
            label: Text(_generating ? 'Analyzing on-device…' : 'Analyze'),
          ),
          const SizedBox(height: 16),
          if (result != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            (result['urgency'] ?? '?')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: _urgencyColor(
                              (result['urgency'] ?? '').toString()),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () => tts.speak(
                              (result['advice'] ?? '').toString(),
                              appState.language),
                          icon: const Icon(Icons.volume_up),
                          tooltip: 'Speak advice',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(context, 'Summary', result['summary']),
                    _field(
                        context,
                        'Possible causes',
                        (result['possible_causes'] as List?)
                                ?.map((c) => '• $c')
                                .join('\n') ??
                            result['possible_causes']),
                    _field(context, 'Advice', result['advice']),
                    _field(context, 'Referral note', result['referral_note']),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  (result['referral_note'] ?? '').toString()));
                          _snack('Referral note copied.');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy referral note'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_raw.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not parse structured output — raw '
                    'response:\n\n$_raw'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Screening aid only — not a diagnosis. Danger signs always mean '
            'immediate referral.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, Object? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(value.toString()),
        ],
      ),
    );
  }
}
