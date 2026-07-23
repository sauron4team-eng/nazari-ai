/// Modèle pour un chunk de texte stocké en base de données
class ChunkModel {
  final int? id;
  final int documentId; // Clé étrangère vers documents.id
  final int chunkIndex; // Position du chunk dans le document (0, 1, 2, ...)
  final String content; // Contenu du chunk
  final int charCount; // Nombre de caractères
  final int?
  pageNumber; // Numéro de page d'origine (PDF uniquement), null sinon
  final DateTime createdAt;

  ChunkModel({
    this.id,
    required this.documentId,
    required this.chunkIndex,
    required this.content,
    required this.charCount,
    this.pageNumber,
    required this.createdAt,
  });

  /// Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'chunkIndex': chunkIndex,
      'content': content,
      'charCount': charCount,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Créer depuis une Map SQLite
  factory ChunkModel.fromMap(Map<String, dynamic> map) {
    return ChunkModel(
      id: map['id'] as int?,
      documentId: map['documentId'] as int,
      chunkIndex: map['chunkIndex'] as int,
      content: map['content'] as String,
      charCount: map['charCount'] as int,
      pageNumber: map['pageNumber'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Copier avec modification
  ChunkModel copyWith({
    int? id,
    int? documentId,
    int? chunkIndex,
    String? content,
    int? charCount,
    int? pageNumber,
    DateTime? createdAt,
  }) {
    return ChunkModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      content: content ?? this.content,
      charCount: charCount ?? this.charCount,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
