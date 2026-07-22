import 'gemma_service.dart';
import 'prompt_engineering.dart';
import '../models/keyword_set.dart';

/// Extrait les keywords/concepts clés via Gemma
class KeywordService {
  final GemmaService _gemma;

  KeywordService(this._gemma);

  Future<KeywordSet> extractKeywords({
    required String content,
    String? title,
    int keywordCount = 15,
  }) async {
    final prompt = PromptEngineering.extractKeywords(content, keywordCount: keywordCount);
    final raw = await _gemma.generate(prompt);

    final json = GemmaService.parseJsonResponse(raw);
    if (json == null) {
      throw FormatException('Gemma did not return valid JSON for keywords. Raw: $raw');
    }

    final set = KeywordSet.fromJson(json);
    return KeywordSet(
      id: set.id,
      title: title ?? json['title'] ?? 'Extracted Keywords',
      sourceDocumentId: '', // rempli par l'appelant
      keywords: set.keywords,
      createdAt: DateTime.now(),
    );
  }

  Future<KeywordSet> extractFromDocument({
    required String documentText,
    required String documentId,
    String? title,
    int keywordCount = 15,
  }) async {
    final set = await extractKeywords(content: documentText, title: title, keywordCount: keywordCount);
    return KeywordSet(
      id: set.id,
      title: set.title,
      sourceDocumentId: documentId,
      keywords: set.keywords,
      createdAt: set.createdAt,
    );
  }
}
