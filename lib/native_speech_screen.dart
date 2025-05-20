import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NativeSpeechScreen extends StatefulWidget {
  const NativeSpeechScreen({super.key});

  @override
  State<NativeSpeechScreen> createState() => _NativeSpeechScreenState();
}

class _NativeSpeechScreenState extends State<NativeSpeechScreen> {
  static const platform = MethodChannel('speech_recognition_channel');
  static const EventChannel eventChannel =
      EventChannel('speech_recognition_stream');
  String _recognizedText = '';
  bool _isRecording = false;
  StreamSubscription? _speechSubscription;

  @override
  void initState() {
    super.initState();
    requestPermission();
    _stopRecording();
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    debugPrint("start recording");
    setState(() {
      _isRecording = true;
      _recognizedText = 'Listening...';
    });
    try {
      eventChannel.receiveBroadcastStream().listen((data) {
        setState(() {
          debugPrint("StreamResult: $data");
          _recognizedText = data as String? ?? '';
        });
      }, onError: (error) {
        setState(() {
          _recognizedText = 'Error mendengarkan: ${error.message}';
          _isRecording = false;
        });
      }, onDone: () {
        setState(() {
          _isRecording = false;
          _recognizedText = 'Perekaman selesai.';
        });
      });
      final String? result = await platform
          .invokeMethod('startRecording')
          .onError((error, stackTrace) {
        debugPrint("Start recording Error: $error");
      });

      debugPrint("Result: $result");
    } on PlatformException catch (e) {
      debugPrint("Start recording Error: ${e.message}");
      setState(() {
        _recognizedText = "Failed Recording: '${e.message}'.";
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      debugPrint("stop recording");
      setState(() {
        _recognizedText = 'Stopping recording...';
      });
      await platform.invokeMethod('stopRecording').then((_) {
        setState(() {
          _isRecording = false;
          _recognizedText = 'Recording stopped.';
        });
      });
      _speechSubscription?.cancel();
    } on PlatformException catch (e) {
      setState(() {
        _recognizedText = "Failed to stop recording: '${e.message}'.";
      });
    }
  }

  Future<void> requestPermission() async {
    debugPrint('Requesting microphone permission');
    final status = await Permission.microphone.request();
    debugPrint('Microphon Status: $status');
    if (status == PermissionStatus.permanentlyDenied) {
      // await openAppSettings();
    }

    debugPrint('Requesting Speech Recognition permission');
    final speechStatus = await Permission.speech.request();
    debugPrint('Speech Recognition Status: $speechStatus');
    if (speechStatus == PermissionStatus.permanentlyDenied) {
      //   await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Recognition'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _recognizedText,
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
