import 'gemma_service.dart';
import 'prompt_engineering.dart';
import '../models/flashcard.dart';

/// Génère des flashcards structurées (JSON) via Gemma
class FlashcardService {
  final GemmaService _gemma;

  FlashcardService(this._gemma);

  Future<FlashcardDeck> generateDeck({
    required String content,
    String? title,
    int cardCount = 20,
  }) async {
    final prompt = PromptEngineering.generateFlashcards(content, cardCount: cardCount);
    final raw = await _gemma.generate(prompt);

    final json = GemmaService.parseJsonResponse(raw);
    if (json == null) {
      throw FormatException('Gemma did not return valid JSON for flashcards. Raw: $raw');
    }

    final deck = FlashcardDeck.fromJson(json);
    return FlashcardDeck(
      id: deck.id,
      title: title ?? json['title'] ?? 'Generated Deck',
      sourceDocumentId: '', // rempli par l'appelant
      cards: deck.cards,
      createdAt: DateTime.now(),
    );
  }

  Future<FlashcardDeck> generateDeckFromDocument({
    required String documentText,
    required String documentId,
    String? title,
    int cardCount = 20,
  }) async {
    final deck = await generateDeck(content: documentText, title: title, cardCount: cardCount);
    return FlashcardDeck(
      id: deck.id,
      title: deck.title,
      sourceDocumentId: documentId,
      cards: deck.cards,
      createdAt: deck.createdAt,
    );
  }
}
