import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/demo_engine.dart';
import 'engine/llama_engine.dart';
import 'engine/model_engine.dart';
import 'prompts.dart';

/// App-wide state: active engine, loaded model, language, prompt templates,
/// and the last raw model output (surfaced in the Prompt Lab).
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;

  ModelEngine engine = DemoEngine();
  String? modelPath;
  String language = 'en-IN';
  String medLensPrompt = Prompts.medLens;
  String triagePrompt = Prompts.triage;
  String lastRawResponse = '';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    language = _prefs.getString('language') ?? 'en-IN';
    medLensPrompt = _prefs.getString('prompt.medLens') ?? Prompts.medLens;
    triagePrompt = _prefs.getString('prompt.triage') ?? Prompts.triage;
    final savedModel = _prefs.getString('modelPath');
    if (savedModel != null && File(savedModel).existsSync()) {
      modelPath = savedModel;
      engine = LlamaEngine(savedModel);
    }
    notifyListeners();
  }

  Future<void> useModel(String path) async {
    modelPath = path;
    engine = LlamaEngine(path);
    await _prefs.setString('modelPath', path);
    notifyListeners();
  }

  Future<void> useDemoEngine() async {
    modelPath = null;
    engine = DemoEngine();
    await _prefs.remove('modelPath');
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    await _prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> savePrompts({String? medLens, String? triage}) async {
    if (medLens != null) {
      medLensPrompt = medLens;
      await _prefs.setString('prompt.medLens', medLens);
    }
    if (triage != null) {
      triagePrompt = triage;
      await _prefs.setString('prompt.triage', triage);
    }
    notifyListeners();
  }

  Future<void> resetPrompts() async {
    medLensPrompt = Prompts.medLens;
    triagePrompt = Prompts.triage;
    await _prefs.remove('prompt.medLens');
    await _prefs.remove('prompt.triage');
    notifyListeners();
  }

  void recordRun(String raw) {
    lastRawResponse = raw;
    notifyListeners();
  }
}

final AppState appState = AppState();
