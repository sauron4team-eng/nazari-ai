class Quiz {
  final String id;
  final String title;
  final String sourceDocumentId;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  int? score;
  int? totalAnswered;

  Quiz({
    required this.id,
    required this.title,
    required this.sourceDocumentId,
    required this.questions,
    required this.createdAt,
    this.score,
    this.totalAnswered,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Untitled Quiz',
        sourceDocumentId: json['sourceDocumentId'] ?? '',
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
        createdAt: DateTime.now(),
        score: json['score'],
        totalAnswered: json['totalAnswered'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceDocumentId': sourceDocumentId,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'score': score,
        'totalAnswered': totalAnswered,
      };
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  int? userAnswerIndex;
  bool? isCorrect;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.userAnswerIndex,
    this.isCorrect,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'],
        options: List<String>.from(json['options']),
        correctIndex: json['correct'],
        explanation: json['explanation'] ?? '',
        userAnswerIndex: json['userAnswerIndex'],
        isCorrect: json['isCorrect'],
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct': correctIndex,
        'explanation': explanation,
        'userAnswerIndex': userAnswerIndex,
        'isCorrect': isCorrect,
      };
}
