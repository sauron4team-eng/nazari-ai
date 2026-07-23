import 'package:flutter/material.dart';
import 'package:nazariai/data/database/database_service.dart';

/// Méthode de debug : affiche tout le contenu de la base dans la console
Future<void> debugPrintAllData() async {
  final docs = await DatabaseService.getAllDocuments();
  debugPrint('=== ${docs.length} document(s) en base ===');

  for (final doc in docs) {
    debugPrint(
      '📄 ${doc.fileName} | id=${doc.id} | ${doc.totalChunks} chunks | hash=${doc.fileHash}',
    );

    final chunks = await DatabaseService.getChunksByDocumentId(doc.id!);
    for (final c in chunks) {
      final preview = c.content.length > 60
          ? c.content.substring(0, 60)
          : c.content;
      debugPrint(
        '   └─ chunk ${c.chunkIndex} (page ${c.pageNumber}) : $preview...',
      );
    }
  }
}
