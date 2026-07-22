class Document {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType; // 'pdf' | 'docx' | 'image' | 'txt'
  final String extractedText;
  final int pageCount;
  final DateTime uploadedAt;
  final int tokenEstimate;

  Document({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.extractedText,
    this.pageCount = 0,
    required this.uploadedAt,
    this.tokenEstimate = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'fileType': fileType,
        'extractedText': extractedText,
        'pageCount': pageCount,
        'uploadedAt': uploadedAt.toIso8601String(),
        'tokenEstimate': tokenEstimate,
      };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'],
        fileName: map['fileName'],
        filePath: map['filePath'],
        fileType: map['fileType'],
        extractedText: map['extractedText'],
        pageCount: map['pageCount'] ?? 0,
        uploadedAt: DateTime.parse(map['uploadedAt']),
        tokenEstimate: map['tokenEstimate'] ?? 0,
      );
}
