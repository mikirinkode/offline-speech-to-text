// /*
//  * Copyright (c) 田梓萱[小草林] 2021-2024.
//  * All Rights Reserved.
//  * All codes are protected by China's regulations on the protection of computer software, and infringement must be investigated.
//  * 版权所有 (c) 田梓萱[小草林] 2021-2024.
//  * 所有代码均受中国《计算机软件保护条例》保护，侵权必究.
//  */

// import "dart:io";

// import "package:flutter/material.dart";
// import "package:flutter/services.dart";
// import "package:path_provider/path_provider.dart";
// import "package:whisper_flutter_new/whisper_flutter_new.dart";

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ProviderScope(
//       child: MaterialApp(
//         title: "Whisper for Flutter",
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(
//               seedColor: Theme.of(context).colorScheme.primary),
//           useMaterial3: true,
//         ),
//         home: const MyHomePage(),
//       ),
//     );
//   }
// }

// class TranscribeResult {
//   const TranscribeResult({
//     required this.transcription,
//     required this.time,
//   });

//   final WhisperTranscribeResponse transcription;
//   final Duration time;
// }


// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   WhisperModel model = WhisperModel.base;
//   String lang = "auto";
//   bool translate = false;
//   bool withSegments = false;
//   bool splitWords = false;

//   TranscribeResult? result;
//   bool isLoading = false;

//   Future<void> transcribe(String filePath) async {
//     setState(() => isLoading = true);

//     final Whisper whisper = Whisper(
//       model: model,
//       downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main",
//     );

//     final Directory docDir = await getApplicationDocumentsDirectory();
//     // final WhisperAudioconvert converter = WhisperAudioconvert(
//     //   audioInput: File(filePath),
//     //   audioOutput: File("${docDir.path}/convert.wav"),
//     // );

//     final DateTime start = DateTime.now();

//     try {
//       // final File? converted = await converter.convert();
//       final transcription = await whisper.transcribe(
//         transcribeRequest: TranscribeRequest(
//           audio:  filePath,
//           language: lang,
//           isTranslate: translate,
//           isNoTimestamps: !withSegments,
//           splitOnWord: splitWords,
//           threads: 4,
//           nProcessors: 4,
//         ),
//       );

//       setState(() {
//         result = TranscribeResult(
//           transcription: transcription,
//           time: DateTime.now().difference(start),
//         );
//       });
//     } catch (e) {
//       debugPrint("Error: $e");
//     }

//     setState(() => isLoading = false);
//   }
// }
