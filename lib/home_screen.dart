import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recorder = AudioRecorder();
  bool _isModelInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  Duration? _processingDuration;
  String _fullTranscript = "";
  String? _sampleAudioPath;

  Whisper? whisper;

  @override
  void initState() {
    super.initState();
    _copyModelToDocumentsDirectory();
    _copyAudioToDocumentsDirectory();

    //init whisper
    _isModelInitialized = false;
    getApplicationDocumentsDirectory().then((value) {
      whisper = Whisper(
        model: WhisperModel.base,
        modelDir: value.path,
        // downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main", // comment to fully use local model
      );
      _isModelInitialized = true;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _copyModelToDocumentsDirectory() async {
    final data = await rootBundle.load('assets/ggml-base.bin');
    final bytes = data.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/ggml-base.bin';
    await File(filePath).writeAsBytes(bytes);
  }

  Future<void> _copyAudioToDocumentsDirectory() async {
    final data = await rootBundle.load('assets/jfk.wav');
    final bytes = data.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    _sampleAudioPath = '${dir.path}/jfk.wav';
    await File(_sampleAudioPath!).writeAsBytes(bytes);
  }

  Future<void> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vosk Flutter'),
      ),
      body: _manualRecordView(),
    );
  }

  Widget _manualRecordView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _testSampleAudio();
                  },
                  child: Text("Test sample"),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () async {
                    if (_isListening) {
                      await _stopRecording();
                    } else {
                      try {
                        await requestMicrophonePermission(); // Request permission
                        await _recordAudio();
                      } catch (e) {
                        debugPrint("error trying to record audio: $e");
                      }
                    }
                    setState(() => _isListening = !_isListening);
                  },
                  child: Text(_isListening ? "Stop recording" : "Record audio"),
                ),
              ],
            ),
            Visibility(
              visible: _isProcessing,
              child: const CircularProgressIndicator(),
            ),
            Visibility(
              visible: _fullTranscript != "",
              child: Text(
                  "Final recognition result (${_processingDuration?.inMilliseconds} ms): $_fullTranscript"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordAudio() async {
    try {
      debugPrint("start recording");
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
    debugPrint("stop recording");
    try {
      final startTime = DateTime.now();
      setState(() {
        _isProcessing = true;
        _processingDuration = null; // reset previous value
        _fullTranscript = "";
      });

      // use audio recorder
      final filePath = await _recorder.stop();

      debugPrint("filepath: $filePath");
      if (filePath != null) {
        final bytes = File(filePath).readAsBytesSync();
        await File(filePath).writeAsBytes(
          bytes.buffer.asUint8List(),
        );
        final transcription = await whisper?.transcribe(
          transcribeRequest: TranscribeRequest(
            audio: filePath,
            isTranslate: false,
            isNoTimestamps: false, // Get segments in result
            splitOnWord: true, // Split segments on each word
          ),
        );
        debugPrint("result: ${transcription?.text}");
        final endTime = DateTime.now();
        setState(() {
          _isProcessing = false;
          _processingDuration = endTime.difference(startTime);
          _fullTranscript = transcription?.text ?? "";
        });
      }
    } catch (e) {
      debugPrint("error stopping recording: $e");
    }
  }

  void _testSampleAudio() async {
    try {
      debugPrint("test sample audio");
      final String? filePath = _sampleAudioPath;

      debugPrint("filepath: $filePath");
      if (filePath != null) {
        final startTime = DateTime.now();
        setState(() {
          _isProcessing = true;
          _processingDuration = null; // reset previous value
          _fullTranscript = "";
        });
        final transcription = await whisper?.transcribe(
          transcribeRequest: TranscribeRequest(
            audio: filePath,
            isTranslate: false,
            isNoTimestamps: false,
            splitOnWord: true,
          ),
        );
        debugPrint("result: ${transcription?.text}");
        final endTime = DateTime.now();
        setState(() {
          _isProcessing = false;
          _processingDuration = endTime.difference(startTime);
          _fullTranscript = transcription?.text ?? "";
        });
      }
    } catch (e) {
      debugPrint("error sample audio: $e");
    }
  }
}
