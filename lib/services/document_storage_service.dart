import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:nazariai/services/documents_service.dart';
import 'package:nazariai/data/database/database_service.dart';
import 'package:nazariai/data/models/document_model.dart';
import 'package:nazariai/data/models/chunk_model.dart';

/// Service pour gérer le stockage des documents et chunks en base de données
/// Intègre extraction de contenu + persistance SQLite
class DocumentStorageService {
  /// Traiter et stocker un document complet en base de données
  /// Retourne le DocumentModel stocké ou null en cas d'erreur
  static Future<DocumentModel?> processAndStoreDocumentToDatabase(
    String filePath, {
    String? notes,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        return null;
      }

      // Générer le hash du fichier
      final hash = await _generateFileHash(filePath);
      debugPrint('File hash: $hash');

      // Vérifier si le document existe déjà en base
      final existingDoc = await DatabaseService.getDocumentByHash(hash);
      if (existingDoc != null) {
        debugPrint('Document already in database: ${existingDoc.fileName}');
        return existingDoc;
      }

      // Extraire les métadonnées de base
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final extension = file.path.split('.').last.toLowerCase();

      // extractChunksFromFile remplace extractTextFromFile + chunkDocumentText :
      // il retourne directement List<DocumentChunk>, avec pageNumber renseigné
      // pour les PDF (un chunk par page) et null pour les autres formats.
      final chunks = await DocumentsService.extractChunksFromFile(filePath);
      if (chunks.isEmpty) {
        debugPrint('No content extracted from document');
        return null;
      }

      // Créer le document
      final docModel = DocumentModel(
        fileName: fileName,
        filePath: filePath,
        fileType: extension,
        fileSize: fileSize,
        fileHash: hash,
        createdAt: DateTime.now(),
        totalChunks: chunks.length,
        notes: notes,
      );

      // Insérer le document
      final docId = await DatabaseService.insertDocument(docModel);
      debugPrint('Document stored with ID: $docId');

      // Insérer les chunks, en reliant chacun au document via documentId
      // et en conservant le pageNumber (null pour txt/docx/doc)
      final chunkModels = chunks
          .asMap()
          .entries
          .map(
            (entry) => ChunkModel(
              documentId: docId,
              chunkIndex: entry.key,
              content: entry.value.text,
              pageNumber: entry.value.pageNumber,
              charCount: entry.value.text.length,
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      await DatabaseService.insertChunks(chunkModels);
      debugPrint('Stored ${chunks.length} chunks for document $docId');

      // Retourner le document avec l'ID généré
      return docModel.copyWith(id: docId);
    } catch (e) {
      debugPrint('Error processing document: $e');
      rethrow;
    }
  }

  /// Récupérer tous les documents stockés
  static Future<List<DocumentModel>> getAllStoredDocuments() async {
    try {
      return await DatabaseService.getAllDocuments();
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return [];
    }
  }

  /// Récupérer les chunks d'un document
  static Future<List<ChunkModel>> getDocumentChunks(int documentId) async {
    try {
      return await DatabaseService.getChunksByDocumentId(documentId);
    } catch (e) {
      debugPrint('Error fetching chunks: $e');
      return [];
    }
  }

  /// Récupérer uniquement les chunks d'une page donnée d'un document
  /// (utile pour les PDF ; pageNumber en 1-indexed, comme affiché à l'utilisateur)
  static Future<List<ChunkModel>> getDocumentChunksForPage(
    int documentId,
    int pageNumber,
  ) async {
    try {
      final chunks = await DatabaseService.getChunksByDocumentId(documentId);
      return chunks.where((c) => c.pageNumber == pageNumber).toList();
    } catch (e) {
      debugPrint('Error fetching chunks for page: $e');
      return [];
    }
  }

  /// Récupérer un document avec tous ses chunks
  static Future<Map<String, dynamic>?> getDocumentWithChunks(
    int documentId,
  ) async {
    try {
      return await DatabaseService.getDocumentWithChunks(documentId);
    } catch (e) {
      debugPrint('Error fetching document with chunks: $e');
      return null;
    }
  }

  /// Obtenir le texte complet d'un document (tous les chunks joints)
  /// Insère des marqueurs [Page N] quand le document a une pagination (PDF)
  static Future<String> getFullDocumentText(int documentId) async {
    try {
      final chunks = await getDocumentChunks(documentId);
      final buffer = StringBuffer();
      int? lastPage;
      for (final chunk in chunks) {
        if (chunk.pageNumber != null && chunk.pageNumber != lastPage) {
          buffer.writeln('\n[Page ${chunk.pageNumber}]');
          lastPage = chunk.pageNumber;
        }
        buffer.writeln(chunk.content);
      }
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('Error getting full document text: $e');
      return '';
    }
  }

  /// Mettre à jour les notes d'un document
  static Future<void> updateDocumentNotes(int documentId, String notes) async {
    try {
      final doc = await DatabaseService.getDocumentById(documentId);
      if (doc != null) {
        final updated = doc.copyWith(notes: notes, updatedAt: DateTime.now());
        await DatabaseService.updateDocument(updated);
        debugPrint('Document notes updated');
      }
    } catch (e) {
      debugPrint('Error updating document notes: $e');
    }
  }

  /// Supprimer un document et tous ses chunks
  static Future<void> deleteDocument(int documentId) async {
    try {
      await DatabaseService.deleteDocument(documentId);
      debugPrint('Document and associated chunks deleted');
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
  }

  /// Rechercher des documents par nom
  static Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      final allDocs = await getAllStoredDocuments();
      return allDocs
          .where(
            (doc) =>
                doc.fileName.toLowerCase().contains(query.toLowerCase()) ||
                doc.notes?.toLowerCase().contains(query.toLowerCase()) == true,
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching documents: $e');
      return [];
    }
  }

  /// Obtenir les statistiques
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await DatabaseService.getStatistics();
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      return {'documents': 0, 'chunks': 0, 'totalSize': 0};
    }
  }

  /// Vérifier si un fichier a changé depuis sa dernière analyse
  static Future<bool> hasFileChanged(int documentId) async {
    try {
      final doc = await DatabaseService.getDocumentById(documentId);
      if (doc == null) return false;

      final file = File(doc.filePath);
      if (!await file.exists()) return true;

      final newHash = await _generateFileHash(doc.filePath);
      return newHash != doc.fileHash;
    } catch (e) {
      debugPrint('Error checking if file changed: $e');
      return true;
    }
  }

  /// Réanalyser un document (si le fichier a changé)
  static Future<DocumentModel?> reanalyzeDocument(int documentId) async {
    try {
      final doc = await DatabaseService.getDocumentById(documentId);
      if (doc == null) return null;

      // Supprimer les anciens chunks
      await DatabaseService.deleteChunksByDocumentId(documentId);

      // Réanalyser le fichier avec la nouvelle API (List<DocumentChunk>)
      final newChunks = await DocumentsService.extractChunksFromFile(
        doc.filePath,
      );
      if (newChunks.isEmpty) return null;

      // Insérer les nouveaux chunks, en conservant le pageNumber
      final chunkModels = newChunks
          .asMap()
          .entries
          .map(
            (entry) => ChunkModel(
              documentId: documentId,
              chunkIndex: entry.key,
              content: entry.value.text,
              pageNumber: entry.value.pageNumber,
              charCount: entry.value.text.length,
              createdAt: DateTime.now(),
            ),
          )
          .toList();

      await DatabaseService.insertChunks(chunkModels);

      // Mettre à jour le document
      final newHash = await _generateFileHash(doc.filePath);
      final updatedDoc = doc.copyWith(
        totalChunks: newChunks.length,
        fileHash: newHash,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateDocument(updatedDoc);
      debugPrint('Document reanalyzed: ${doc.fileName}');

      return updatedDoc;
    } catch (e) {
      debugPrint('Error reanalyzing document: $e');
      return null;
    }
  }

  /// Générer un hash MD5 du fichier
  static Future<String> _generateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return md5.convert(bytes).toString();
    } catch (e) {
      debugPrint('Error generating file hash: $e');
      rethrow;
    }
  }
}
