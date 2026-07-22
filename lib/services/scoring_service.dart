import '../models/quiz.dart';
import '../models/flashcard.dart';

/// Évalue les réponses aux quiz/flashcards et calcule le score
class ScoringService {
  /// Évalue un quiz complet et retourne le score en pourcentage
  static QuizScore evaluateQuiz(Quiz quiz) {
    int correct = 0;
    int total = quiz.questions.length;

    for (final q in quiz.questions) {
      if (q.userAnswerIndex != null) {
        q.isCorrect = q.userAnswerIndex == q.correctIndex;
        if (q.isCorrect!) correct++;
      }
    }

    final percent = total > 0 ? ((correct / total) * 100).round() : 0;

    return QuizScore(
      correct: correct,
      total: total,
      percentage: percent,
      answered: quiz.questions.where((q) => q.userAnswerIndex != null).length,
    );
  }

  /// Évalue une session de flashcards
  static FlashcardScore evaluateFlashcards(FlashcardDeck deck) {
    int known = 0;
    int reviewed = 0;

    for (final card in deck.cards) {
      if (card.reviewed) {
        reviewed++;
        if (card.known == true) known++;
      }
    }

    final percent = reviewed > 0 ? ((known / reviewed) * 100).round() : 0;

    return FlashcardScore(
      known: known,
      reviewed: reviewed,
      total: deck.cards.length,
      percentage: percent,
    );
  }

  /// Calcule un score global pour l'affichage dans "Recent Results"
  static double calculateOverallScore(List<QuizScore> quizScores, List<FlashcardScore> flashScores) {
    double total = 0;
    int count = 0;
    for (final s in quizScores) {
      total += s.percentage;
      count++;
    }
    for (final s in flashScores) {
      total += s.percentage;
      count++;
    }
    return count > 0 ? total / count : 0;
  }
}

class QuizScore {
  final int correct;
  final int total;
  final int percentage;
  final int answered;

  QuizScore({
    required this.correct,
    required this.total,
    required this.percentage,
    required this.answered,
  });
}

class FlashcardScore {
  final int known;
  final int reviewed;
  final int total;
  final int percentage;

  FlashcardScore({
    required this.known,
    required this.reviewed,
    required this.total,
    required this.percentage,
  });
}
