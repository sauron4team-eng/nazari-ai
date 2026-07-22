import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'prompt_engineering.dart';

/// Service d'inférence Gemma 4.
/// 
/// Architecture:
/// - `_GemmaBackend` est une abstraction du backend LLM.
/// - `_MockGemmaBackend` simule les réponses pour le développement sans modèle.
/// - `_RealGemmaBackend` est prête à brancher `flutter_gemma` ou `flutter_gemma_litertlm`.
///
/// Pour passer en mode réel, remplacez `_backend` dans le constructeur.

class GemmaService extends ChangeNotifier {
  late final _GemmaBackend _backend;
  bool _isGenerating = false;
  String? _lastResponse;

  bool get isGenerating => _isGenerating;
  String? get lastResponse => _lastResponse;

  GemmaService({bool useMock = true}) {
    _backend = useMock ? _MockGemmaBackend() : _RealGemmaBackend();
  }

  /// Initialise le modèle avec le chemin du fichier .litertlm
  Future<void> initialize(String modelPath) async {
    await _backend.initialize(modelPath);
  }

  /// Génère une réponse complète (non-streaming)
  Future<String> generate(String prompt, {String? systemInstruction}) async {
    _isGenerating = true;
    _lastResponse = null;
    notifyListeners();

    try {
      final response = await _backend.generate(
        prompt,
        systemInstruction: systemInstruction ?? PromptEngineering.systemInstruction,
      );
      _lastResponse = response;
      return response;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Génère avec streaming (pour le chat en temps réel)
  Stream<String> generateStream(String prompt, {String? systemInstruction}) async* {
    _isGenerating = true;
    notifyListeners();

    try {
      await for (final chunk in _backend.generateStream(
        prompt,
        systemInstruction: systemInstruction ?? PromptEngineering.systemInstruction,
      )) {
        _lastResponse = (_lastResponse ?? '') + chunk;
        yield chunk;
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Parse une réponse JSON de Gemma (tolérant aux markdown fences)
  static Map<String, dynamic>? parseJsonResponse(String raw) {
    String cleaned = raw.trim();
    // Enlève les fences markdown ```json ... ```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      // Fallback: essaie d'extraire le premier bloc JSON
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        try {
          return jsonDecode(cleaned.substring(start, end + 1)) as Map<String, dynamic>;
        } catch (_) {}
      }
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  BACKEND ABSTRACTION
// ═══════════════════════════════════════════════════════════

abstract class _GemmaBackend {
  Future<void> initialize(String modelPath);
  Future<String> generate(String prompt, {required String systemInstruction});
  Stream<String> generateStream(String prompt, {required String systemInstruction});
}

// ═══════════════════════════════════════════════════════════
//  MOCK BACKEND (pour développement sans modèle)
// ═══════════════════════════════════════════════════════════

class _MockGemmaBackend implements _GemmaBackend {
  @override
  Future<void> initialize(String modelPath) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String> generate(String prompt, {required String systemInstruction}) async {
    await Future.delayed(const Duration(seconds: 1));

    if (prompt.contains('quiz') || prompt.contains('Quiz')) {
      return jsonEncode({
        "title": "Sample Quiz",
        "questions": [
          {
            "question": "What is the capital of France?",
            "options": ["Paris", "London", "Berlin", "Madrid"],
            "correct": 0,
            "explanation": "Paris is the capital and most populous city of France."
          },
          {
            "question": "What is 2 + 2?",
            "options": ["3", "4", "5", "6"],
            "correct": 1,
            "explanation": "Basic arithmetic: 2 + 2 equals 4."
          }
        ]
      });
    }

    if (prompt.contains('flashcard') || prompt.contains('Flashcard')) {
      return jsonEncode({
        "title": "Sample Flashcards",
        "cards": [
          {"front": "Capital of France", "back": "Paris", "tag": "Geography"},
          {"front": "2 + 2", "back": "4", "tag": "Math"},
          {"front": "H2O", "back": "Water", "tag": "Chemistry"}
        ]
      });
    }

    if (prompt.contains('keyword') || prompt.contains('Keyword')) {
      return jsonEncode({
        "title": "Sample Keywords",
        "keywords": [
          {"term": "Photosynthesis", "definition": "Process by which plants convert light energy into chemical energy.", "context": "Biology chapter 3"},
          {"term": "Newton's First Law", "definition": "An object remains at rest or in uniform motion unless acted upon by a force.", "context": "Physics fundamentals"}
        ]
      });
    }

    if (prompt.contains('title') || prompt.contains('Title')) {
      return "Introduction to Biology";
    }

    return "This is a mock response from NazariAI. In production, this will be generated by Gemma 4 running locally on your device.";
  }

  @override
  Stream<String> generateStream(String prompt, {required String systemInstruction}) async* {
    final words = [
      "This ", "is ", "a ", "streaming ", "response ", "from ", "NazariAI. ",
      "Gemma ", "4 ", "is ", "processing ", "your ", "request ", "locally."
    ];
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 80));
      yield word;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  REAL BACKEND (à brancher avec flutter_gemma)
// ═══════════════════════════════════════════════════════════
/// 
/// TODO: Installer le package flutter_gemma dans pubspec.yaml
///       puis décommenter et adapter le code ci-dessous.
///
/// Pour flutter_gemma (MediaPipe .task):
///   import 'package:flutter_gemma/flutter_gemma.dart';
///   final model = await InferenceModel.create(modelPath: modelPath);
///   final response = await model.generateResponse(prompt);
///
/// Pour flutter_gemma_litertlm (si dispo):
///   import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
///   final model = await GemmaModel.load(modelPath);
///   final response = await model.generate(prompt);

class _RealGemmaBackend implements _GemmaBackend {
  // dynamic _model; // LlmInference ou GemmaModel

  @override
  Future<void> initialize(String modelPath) async {
    // TODO: _model = await LlmInference.create(modelPath: modelPath);
    throw UnimplementedError('Brancher flutter_gemma ici. Voir les commentaires dans le fichier.');
  }

  @override
  Future<String> generate(String prompt, {required String systemInstruction}) async {
    // TODO: return await _model.generateResponse(prompt);
    throw UnimplementedError();
  }

  @override
  Stream<String> generateStream(String prompt, {required String systemInstruction}) async* {
    // TODO: yield* _model.generateResponseAsync(prompt);
    throw UnimplementedError();
  }
}
