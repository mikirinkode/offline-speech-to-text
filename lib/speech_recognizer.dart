import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import for StatefulWidget
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognizer {
  // Use a ValueNotifier to manage state changes
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  // bool get isListening => _isListening.value;

  final ValueNotifier<bool> isEnabled = ValueNotifier<bool>(false);
  // bool get isEnabled => _isEnabled.value;

  late SpeechToText _speech;
  Function(String)? _controllerCallback;

  // Constructor
  SpeechRecognizer() {
    _speech = SpeechToText(); // Initialize in the constructor
  }

  Future<void> init() async {
    isEnabled.value = await _speech.initialize(
      onStatus: (val) async {
        if (isListening.value && val == "notListening") {
          await _speech.stop();
          await continueListening(onResultCallback: _controllerCallback);
        }
        _notifyListeners(); // Notify listeners of state changes
      },
      onError: (val) {
        if (kDebugMode) {
          print("onError: $val");
        }
        _notifyListeners();
      },
      finalTimeout: const Duration(minutes: 5),
      options: [
        SpeechToText.androidAlwaysUseStop,
      ],
    );
    _notifyListeners();
  }

  Future<void> continueListening({required Function(String)? onResultCallback}) async {
    _controllerCallback = onResultCallback; // update the callback
    if (isEnabled.value) {
      isListening.value = true;
      _notifyListeners();
      _speech.listen(
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
        onResult: (val) {
          _controllerCallback?.call(val.recognizedWords);
        },
      );
    }
  }

  Future<void> stopListening() async {
    isListening.value = false;
    _notifyListeners();
    await _speech.stop();
  }

  void dispose() async {
    isListening.dispose();
    isEnabled.dispose();
    if (_speech.isListening) {
      await _speech.stop();
      await _speech.cancel();
    }
  }

  //helper method to notify the listeners.
    void _notifyListeners() {
    // This is a helper method to notify the listeners.
    // In a simple class, you would manually notify your UI (StatefulWidget)
    // about changes, typically using setState().  Since we're not extending
    // ChangeNotifier, we can't use notifyListeners().  Instead, we use the
    // ValueNotifier.
      isListening.notifyListeners();
      isEnabled.notifyListeners();
  }
}
