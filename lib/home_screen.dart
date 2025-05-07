import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:record/record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _modelPath = 'assets/models/vosk-model-small-en-us-0.15.zip';
  static const _sampleRate = 16000;

  late VoskFlutterPlugin _vosk;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  final _recorder = AudioRecorder();
  String? _fileRecognitionResult;
  bool _isListening = false;
  bool _isProcessing = false;
  Duration? _processingDuration;
  late StreamSubscription? _resultSub;
  bool speechServiceInitialized = false;
  String _fullTranscript = "";

  @override
  void initState() {
    super.initState();

    _vosk = VoskFlutterPlugin.instance();

    ModelLoader().loadFromAssets(_modelPath).then((modelPath) {
      _vosk.createModel(modelPath).then((model) {
        _vosk
            .createRecognizer(
          model: model,
          sampleRate: _sampleRate,
        )
            .then((recognizer) {
          _recognizer = recognizer;
          if (!speechServiceInitialized) {
            _vosk.initSpeechService(recognizer).then((speechService) {
              debugPrint("Ready");
              setState(() {
                _speechService = speechService;
                speechServiceInitialized = true;
              });

              _resultSub = speechService.onResult().listen((json) {
                setState(() {
                  if (json.isNotEmpty) {
                    final Map<String, dynamic> partialMap =
                        jsonDecode(json);
                    final text = partialMap['text'] ?? '';
                    _fullTranscript += text;
                  }
                });
              });
            });
          } else {
            debugPrint("SpeechService already initialized");
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _speechService?.cancel();
    _speechService?.reset();
    _speechService?.dispose();
    _recorder.dispose();
    _resultSub?.cancel();
    _speechService = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vosk Flutter'),
      ),
      body: _voskSpeechServiceView(),
      // body: _manualRecordView(),
    );
  }

  Widget _voskSpeechServiceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(
          onPressed: () {
            if (_isListening) {
              _speechService?.stop().then((_) {
                setState(() {
                  _isListening = false;
                });
              });
            } else {
              _speechService?.start().then((_) {
                setState(() {
                  _isListening = true;
                });
              });
            }
          },
          child: Text(_isListening ? "Stop recording" : "Record audio"),
        ),
        SizedBox(
          width: double.infinity,
          child: StreamBuilder(
            stream: _speechService?.onPartial(),
            builder: (context, snapshot) => Text(
              "Partial result: ${snapshot.data.toString()}",
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: StreamBuilder(
            stream: _speechService?.onResult(),
            builder: (context, snapshot) => Text(
              "Result: ${snapshot.data.toString()}",
            ),
          ),
        ),
      ],
    );
  }

  Widget _manualRecordView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () async {
                if (_isListening) {
                  final startTime = DateTime.now();
                  setState(() {
                    _isProcessing = true;
                    _processingDuration = null; // reset previous value
                  });

                  await _stopRecording();

                  final endTime = DateTime.now();
                  setState(() {
                    _isProcessing = false;
                    _processingDuration = endTime.difference(startTime);
                  });
                } else {
                  await _recordAudio();
                }
                setState(() => _isListening = !_isListening);
              },
              child: Text(_isListening ? "Stop recording" : "Record audio"),
            ),
            Visibility(
              visible: _isProcessing,
              child: const CircularProgressIndicator(),
            ),
            Visibility(
              visible: _fileRecognitionResult != null,
              child: Text(
                  "Final recognition result (${_processingDuration?.inMilliseconds} ms): $_fileRecognitionResult"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordAudio() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/audio.wav';
      await _recorder.start(
        const RecordConfig(
          sampleRate: 16000,
          encoder: AudioEncoder.wav,
          numChannels: 1,
        ),
        path: filePath,
      );
    } catch (e) {
      debugPrint("error recording audio: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await _recorder.stop();
      if (filePath != null) {
        final bytes = File(filePath).readAsBytesSync();
        _recognizer?.acceptWaveformBytes(bytes);
        _fileRecognitionResult = await _recognizer?.getFinalResult();
      }
    } catch (e) {
      debugPrint("error stopping recording: $e");
    }
  }
}
