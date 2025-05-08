import 'package:flutter/material.dart';

import 'speech_recognizer.dart';

class HomeAltScreen extends StatefulWidget {
  const HomeAltScreen({super.key});

  @override
  State<HomeAltScreen> createState() => _HomeAltScreenState();
}

class _HomeAltScreenState extends State<HomeAltScreen> {
  final SpeechRecognizer _speechRecognizer = SpeechRecognizer();
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speechRecognizer.init().then((_) {
      //initialization complete
      if (mounted) { //check if the widget is mounted before calling setState
        setState(() {});
      }
    });

    _speechRecognizer.isListening.addListener(_onIsListeningChanged);
    _speechRecognizer.isEnabled.addListener(_onIsEnabledChanged);
  }

  void _onIsListeningChanged() {
    if (mounted) {
      setState(() {}); // Rebuild the UI when listening state changes
    }
  }

    void _onIsEnabledChanged() {
    if (mounted) {
      setState(() {}); // Rebuild the UI when listening state changes
    }
  }

  @override
  void dispose() {
    _speechRecognizer.dispose();
    _speechRecognizer.isListening.removeListener(_onIsListeningChanged);
    _speechRecognizer.isEnabled.removeListener(_onIsEnabledChanged);
    super.dispose();
  }

  void _startListening() {
    _speechRecognizer.continueListening(
      onResultCallback: (text) {
        setState(() {
          _recognizedText = text;
        });
      },
    );
  }

  void _stopListening() {
    _speechRecognizer.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Recognition Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Is Listening: ${_speechRecognizer.isListening.value}',
              style: const TextStyle(fontSize: 20),
            ),
             Text(
              'Is Enabled: ${_speechRecognizer.isEnabled.value}',
              style: const TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Recognized Text: $_recognizedText',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: _speechRecognizer.isEnabled.value
                  ? (_speechRecognizer.isListening.value ? _stopListening : _startListening)
                  : null, // Disable if not enabled
              child: Text(
                _speechRecognizer.isListening.value ? 'Stop Listening' : 'Start Listening',
              ),
            ),
          ],
        ),
      ),
    );
  }
}