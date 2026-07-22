import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Gère le cycle de vie du modèle Gemma 4 E2B .litertlm
/// - Vérifie si le modèle est installé
/// - Propose téléchargement web ou import local
/// - Gère la barre de progression

class ModelManager extends ChangeNotifier {
  static const String modelFileName = 'gemma-4-E2B-it.litertlm';
  static const int modelFileSizeBytes =
      2400000000; // ~2.4 GB (ajuste selon le vrai poids)
  static const String downloadUrl =
      'https://huggingface.co/google/gemma-4/resolve/main/gemma-4-E2B-it.litertlm';

  ModelStatus _status = ModelStatus.notInstalled;
  double _downloadProgress = 0.0;
  String? _modelPath;
  String? _errorMessage;

  ModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  String? get modelPath => _modelPath;
  String? get errorMessage => _errorMessage;
  bool get isInstalled => _status == ModelStatus.ready;

  ModelManager() {
    _init();
  }

  Future<void> _init() async {
    await checkLocalModel();
  }

  /// Vérifie si le modèle existe dans le dossier app privé
  Future<void> checkLocalModel() async {
    _setStatus(ModelStatus.checking);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File(p.join(appDir.path, modelFileName));

      if (await modelFile.exists()) {
        _modelPath = modelFile.path;
        _setStatus(ModelStatus.ready);
      } else {
        _setStatus(ModelStatus.notInstalled);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(ModelStatus.error);
    }
  }

  /// Importe un fichier .litertlm depuis le gestionnaire de fichiers du téléphone
  Future<void> importFromLocalFile(String sourcePath) async {
    _setStatus(ModelStatus.installing);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destFile = File(p.join(appDir.path, modelFileName));

      await File(sourcePath).copy(destFile.path);

      _modelPath = destFile.path;
      _setStatus(ModelStatus.ready);
    } catch (e) {
      _errorMessage = 'Import failed: \$e';
      _setStatus(ModelStatus.error);
    }
  }

  /// Télécharge le modèle depuis le web avec progression
  /// NOTE: En production, utilisez `dio` avec `onReceiveProgress`.
  Future<void> downloadFromWeb() async {
    _setStatus(ModelStatus.downloading);
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // TODO: Remplacer par un vrai téléchargement HTTP avec dio
      // final dio = Dio();
      // final appDir = await getApplicationDocumentsDirectory();
      // final destPath = p.join(appDir.path, modelFileName);
      // await dio.download(downloadUrl, destPath,
      //   onReceiveProgress: (received, total) {
      //     if (total != -1) {
      //       _downloadProgress = received / total;
      //       notifyListeners();
      //     }
      //   },
      // );

      // Simulation pour le MVP:
      for (int i = 1; i <= 20; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        _downloadProgress = i / 20;
        notifyListeners();
      }

      await checkLocalModel();
    } catch (e) {
      _errorMessage = 'Download failed: \$e';
      _setStatus(ModelStatus.error);
    }
  }

  /// Supprime le modèle local
  Future<void> deleteModel() async {
    if (_modelPath == null) return;
    try {
      final file = File(_modelPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _modelPath = null;
      _setStatus(ModelStatus.notInstalled);
    } catch (e) {
      _errorMessage = 'Delete failed: \$e';
      _setStatus(ModelStatus.error);
    }
  }

  void _setStatus(ModelStatus s) {
    _status = s;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ModelStatus.error) {
      _setStatus(ModelStatus.notInstalled);
    }
  }
}

enum ModelStatus {
  checking,
  notInstalled,
  downloading,
  installing,
  ready,
  error,
}
