class KeywordSet {
  final String id;
  final String title;
  final String sourceDocumentId;
  final List<Keyword> keywords;
  final DateTime createdAt;

  KeywordSet({
    required this.id,
    required this.title,
    required this.sourceDocumentId,
    required this.keywords,
    required this.createdAt,
  });

  factory KeywordSet.fromJson(Map<String, dynamic> json) => KeywordSet(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Untitled Keywords',
        sourceDocumentId: json['sourceDocumentId'] ?? '',
        keywords: (json['keywords'] as List)
            .map((k) => Keyword.fromJson(k))
            .toList(),
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceDocumentId': sourceDocumentId,
        'keywords': keywords.map((k) => k.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class Keyword {
  final String term;
  final String definition;
  final String? context;

  Keyword({
    required this.term,
    required this.definition,
    this.context,
  });

  factory Keyword.fromJson(Map<String, dynamic> json) => Keyword(
        term: json['term'],
        definition: json['definition'],
        context: json['context'],
      );

  Map<String, dynamic> toJson() => {
        'term': term,
        'definition': definition,
        'context': context,
      };
}
