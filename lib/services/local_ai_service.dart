import 'dart:io';
import 'package:flutter_llama/flutter_llama.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalAIService {
  static const String _modelFileName = 'braindler-q4_k_s.gguf';
  static const String _modelUrl = 'https://ollama.com/nativemind/braindler/resolve/latest/braindler-q4_k_s.gguf';
  
  bool _isInitialized = false;
  double _downloadProgress = 0.0;

  bool get isInitialized => _isInitialized;
  double get downloadProgress => _downloadProgress;

  Future<String> get _modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
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
      final path = await _modelPath;
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(request);
      
      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      
      final file = File(path);
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          _downloadProgress = receivedBytes / totalBytes;
          onProgress(_downloadProgress);
        }
      }
      
      await sink.close();
      client.close();
      onComplete();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    final path = await _modelPath;
    final llama = FlutterLlama.instance;
    final config = LlamaConfig(
      modelPath: path,
      nThreads: 4,
      nGpuLayers: 0,
      contextSize: 512,
      batchSize: 512,
      useGpu: false,
      verbose: false,
    );
    await llama.loadModel(config);
    _isInitialized = true;
  }

  Future<String> ask(String weatherContext, String question) async {
    if (!_isInitialized) await initialize();
    
    final prompt = 'Είσαι μετεωρολόγος. Απάντησε σύντομα στα Ελληνικά. ΜΟΝΟ για καιρό.\n\nΔεδομένα:\n$weatherContext\n\nΕρώτηση: $question\n\nΑπάντηση:';
    
    final params = GenerationParams(
      prompt: prompt,
      temperature: 0.7,
      topP: 0.9,
      topK: 40,
      maxTokens: 200,
      repeatPenalty: 1.1,
    );
    
    final response = await FlutterLlama.instance.generate(params);
    return response.text.trim().isEmpty
        ? 'Δεν μπόρεσα να απαντήσω.'
        : response.text.trim();
  }

  void dispose() {
    // dispose handled by FlutterLlama internally
    _isInitialized = false;
  }
}


