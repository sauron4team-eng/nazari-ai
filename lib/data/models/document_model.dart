/// Modèle pour un document stocké en base de données
class DocumentModel {
  final int? id;
  final String fileName;
  final String filePath;
  final String fileType; // txt, pdf, doc, docx
  final int fileSize;
  final String fileHash; // Hash MD5 pour détecter les changements
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int totalChunks; // Nombre de chunks
  final String? notes; // Notes personnelles de l'utilisateur

  DocumentModel({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.fileHash,
    required this.createdAt,
    this.updatedAt,
    required this.totalChunks,
    this.notes,
  });

  /// Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileHash': fileHash,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalChunks': totalChunks,
      'notes': notes,
    };
  }

  /// Créer depuis une Map SQLite
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as int?,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String,
      fileType: map['fileType'] as String,
      fileSize: map['fileSize'] as int,
      fileHash: map['fileHash'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      totalChunks: map['totalChunks'] as int,
      notes: map['notes'] as String?,
    );
  }

  /// Copier avec modification
  DocumentModel copyWith({
    int? id,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? fileHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalChunks,
    String? notes,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalChunks: totalChunks ?? this.totalChunks,
      notes: notes ?? this.notes,
    );
  }
}
