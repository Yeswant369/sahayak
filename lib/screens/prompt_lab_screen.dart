import 'package:flutter/material.dart';

import '../app_state.dart';

/// Prompt Lab: the on-device dev console. During phone-only hackathon windows
/// ("Red Light"), prompt templates are tuned and re-tested here without a
/// laptop — the phone is the workstation.
class PromptLabScreen extends StatefulWidget {
  const PromptLabScreen({super.key});

  @override
  State<PromptLabScreen> createState() => _PromptLabScreenState();
}

class _PromptLabScreenState extends State<PromptLabScreen> {
  late final TextEditingController _medLens =
      TextEditingController(text: appState.medLensPrompt);
  late final TextEditingController _triage =
      TextEditingController(text: appState.triagePrompt);
  final _testInput = TextEditingController(
      text: 'Paracetamol 500 mg tablets. Dose: 1 tablet every 6 hours.');
  String _testOutput = '';
  bool _running = false;

  @override
  void dispose() {
    _medLens.dispose();
    _triage.dispose();
    _testInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await appState.savePrompts(
        medLens: _medLens.text, triage: _triage.text);
    _snack('Prompts saved.');
  }

  Future<void> _reset() async {
    await appState.resetPrompts();
    _medLens.text = appState.medLensPrompt;
    _triage.text = appState.triagePrompt;
    _snack('Prompts reset to defaults.');
  }

  Future<void> _runTest() async {
    setState(() {
      _running = true;
      _testOutput = '';
    });
    try {
      final result = await appState.engine.generate(
        system: _medLens.text.replaceAll('{language}', 'simple English'),
        user: _testInput.text,
        onUpdate: (textSoFar) {
          if (mounted) setState(() => _testOutput = textSoFar);
        },
      );
      appState.recordRun(result);
      if (mounted) setState(() => _testOutput = result);
    } catch (e) {
      if (mounted) setState(() => _testOutput = 'Error: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tps = appState.engine.lastTokensPerSec;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Lab'),
        actions: [
          IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.restore),
              tooltip: 'Reset to defaults'),
          IconButton(
              onPressed: _save,
              icon: const Icon(Icons.save),
              tooltip: 'Save'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.speed),
              title: Text('Engine: ${appState.engine.label}'),
              subtitle: Text(tps != null
                  ? 'Last run ≈ ${tps.toStringAsFixed(1)} tokens/sec'
                  : 'No timed runs yet'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Medicine Lens template',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _medLens,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Triage template',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _triage,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const Divider(height: 32),
          Text('Quick test (uses Medicine Lens template)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _testInput,
            maxLines: 3,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Test input'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _running ? null : _runTest,
            icon: const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running…' : 'Run'),
          ),
          if (_testOutput.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(_testOutput,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ],
          if (appState.lastRawResponse.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Last raw model output (any screen)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(appState.lastRawResponse,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
