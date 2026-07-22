import 'dart:convert';
import 'gemma_service.dart';
import 'prompt_engineering.dart';
import '../models/quiz.dart';

/// Génère des quizzes structurés (JSON) via Gemma
class QuizService {
  final GemmaService _gemma;

  QuizService(this._gemma);

  Future<Quiz> generateQuiz({
    required String content,
    String? title,
    int questionCount = 10,
  }) async {
    final prompt = PromptEngineering.generateQuiz(content, questionCount: questionCount);
    final raw = await _gemma.generate(prompt);

    final json = GemmaService.parseJsonResponse(raw);
    if (json == null) {
      throw FormatException('Gemma did not return valid JSON for quiz. Raw: $raw');
    }

    final quiz = Quiz.fromJson(json);
    return Quiz(
      id: quiz.id,
      title: title ?? json['title'] ?? 'Generated Quiz',
      sourceDocumentId: '', // rempli par l'appelant si besoin
      questions: quiz.questions,
      createdAt: DateTime.now(),
    );
  }

  /// Génère un quiz depuis un document déjà uploadé
  Future<Quiz> generateQuizFromDocument({
    required String documentText,
    required String documentId,
    String? title,
    int questionCount = 10,
  }) async {
    final quiz = await generateQuiz(
      content: documentText,
      title: title,
      questionCount: questionCount,
    );
    return Quiz(
      id: quiz.id,
      title: quiz.title,
      sourceDocumentId: documentId,
      questions: quiz.questions,
      createdAt: quiz.createdAt,
    );
  }
}
