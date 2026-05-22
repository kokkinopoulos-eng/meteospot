import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

class LocalAIService {
  static const String _modelFileName = 'gemma-2b-it-cpu-int4.bin';
  bool _isInitialized = false;
  double _downloadProgress = 0.0;

  bool get isInitialized => _isInitialized;
  double get downloadProgress => _downloadProgress;

  Future<String> get _modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/$_modelFileName";
  }

  Future<bool> isModelDownloaded() async {
    final path = await _modelPath;
    return File(path).existsSync();
  }

  Future<void> downloadModel({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      const modelUrl = 'https://huggingface.co/google/gemma-2b-it-cpu-int4/resolve/main/gemma-2b-it-cpu-int4.bin';
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(modelUrl)
          .withProgress((progress) {
            _downloadProgress = progress / 100.0;
            onProgress(_downloadProgress);
          })
          .install();
      onComplete();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  Future<String> ask(String weatherContext, String question) async {
    final model = await FlutterGemma.getActiveModel(maxTokens: 512);
    final session = await model.createSession();
    final prompt = 'Είσαι μετεωρολόγος. Απάντησε σύντομα στα Ελληνικά.\n\nΔεδομένα καιρού:\n$weatherContext\n\nΕρώτηση: $question\n\nΑπάντηση:';
    await session.addQueryChunk(Message(text: prompt, isUser: true));
    final response = StringBuffer();
    await for (final token in session.getResponseAsync()) {
      response.write(token);
    }
    await session.close();
    await model.close();
    return response.toString().trim().isEmpty
        ? 'Δεν μπόρεσα να απαντήσω.'
        : response.toString().trim();
  }

  void dispose() {
    _isInitialized = false;
  }
}
