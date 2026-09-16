import 'package:flutter/material.dart';

import '../app_state.dart';
import 'model_screen.dart';
import 'prompt_lab_screen.dart';
import 'scan_screen.dart';
import 'triage_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak'),
        actions: [
          IconButton(
            tooltip: 'Prompt Lab (dev)',
            icon: const Icon(Icons.science_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PromptLabScreen())),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Offline AI health assistant for last-mile care',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Card(
                color: appState.engine.isLocalModel
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    appState.engine.isLocalModel
                        ? Icons.memory
                        : Icons.smart_toy_outlined,
                    color: appState.engine.isLocalModel
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(appState.engine.label,
                      style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Text(appState.engine.isLocalModel
                      ? '100% on-device · works with airplane mode ON'
                      : 'Demo mode — tap to load a local GGUF model'),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ModelScreen())),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Answer language:',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: appState.language,
                    items: const [
                      DropdownMenuItem(
                          value: 'en-IN', child: Text('English')),
                      DropdownMenuItem(value: 'hi-IN', child: Text('हिंदी')),
                      DropdownMenuItem(value: 'te-IN', child: Text('తెలుగు')),
                    ],
                    onChanged: (value) {
                      if (value != null) appState.setLanguage(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.medication_outlined,
                title: 'Medicine Lens',
                subtitle: 'Point the camera at any medicine strip — hear what '
                    'it is, the printed dosage, and warnings.',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanScreen())),
              ),
              _ModuleCard(
                icon: Icons.record_voice_over_outlined,
                title: 'Voice Triage',
                subtitle: 'Describe symptoms by voice — get a cautious '
                    'screening summary, urgency level, and a referral note.',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TriageScreen())),
              ),
              _ModuleCard(
                icon: Icons.tune,
                title: 'Model Manager',
                subtitle: 'Hot-swap any GGUF model — Qwen, Gemma, Granite, '
                    'Sarvam. Tiered for low-end phones to flagships.',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ModelScreen())),
              ),
              const SizedBox(height: 16),
              Text(
                'Screening support only — never a diagnosis.\n'
                'Built phone-first',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
