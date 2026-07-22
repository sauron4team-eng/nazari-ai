class FlashcardDeck {
  final String id;
  final String title;
  final String sourceDocumentId;
  final List<Flashcard> cards;
  final DateTime createdAt;

  FlashcardDeck({
    required this.id,
    required this.title,
    required this.sourceDocumentId,
    required this.cards,
    required this.createdAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Untitled Deck',
        sourceDocumentId: json['sourceDocumentId'] ?? '',
        cards: (json['cards'] as List)
            .map((c) => Flashcard.fromJson(c))
            .toList(),
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceDocumentId': sourceDocumentId,
        'cards': cards.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class Flashcard {
  final String front;
  final String back;
  final String? tag;
  bool reviewed;
  bool? known;

  Flashcard({
    required this.front,
    required this.back,
    this.tag,
    this.reviewed = false,
    this.known,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        front: json['front'],
        back: json['back'],
        tag: json['tag'],
        reviewed: json['reviewed'] ?? false,
        known: json['known'],
      );

  Map<String, dynamic> toJson() => {
        'front': front,
        'back': back,
        'tag': tag,
        'reviewed': reviewed,
        'known': known,
      };
}
