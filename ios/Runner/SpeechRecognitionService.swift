//
//  SpeechRecognitionService.swift
//  Runner
//
//  Created by Wafa on 20/05/25.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: NSObject {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var resultCallback: ((String) -> Void)?
    private var errorCallback: ((String) -> Void)?

    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer()
    }

    func startRecording(result: @escaping (String) -> Void, error: @escaping (String) -> Void) {
        self.resultCallback = result
        self.errorCallback = error

        // SFSpeechRecognizer.requestAuthorization { authStatus in
        //     DispatchQueue.main.async {
        //         switch authStatus {
        //         case .authorized:
        //             print("Speech recognition authorized")
                    self.setupAudioEngineAndRecognition()
        //         case .denied:
        //             print("Speech recognition denied")
        //             self.errorCallback?("Speech recognition access denied by user.")
        //         case .restricted:
        //             print("Speech recognition restricted")
        //             self.errorCallback?("Speech recognition restricted on this device.")
        //         case .notDetermined:
        //             print("Speech recognition not yet determined")
        //             self.errorCallback?("Speech recognition not yet authorized.")
        //         @unknown default:
        //             print("Unknown speech recognition authorization status")
        //             self.errorCallback?("Unknown speech recognition error.")
        //         }
        //     }
        // }
    }

    private func setupAudioEngineAndRecognition() {
        do {
            audioEngine = AVAudioEngine()
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let inputNode = audioEngine?.inputNode
            let recordingFormat = inputNode?.outputFormat(forBus: 0)
            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine?.prepare()
            try audioEngine?.start()

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
                guard let self = self else { return }
                self.recognitionHandler(audioEngine: self.audioEngine, result: result, error: error)
            }
        } catch {
            print("Error setting up audio engine: \(error)")
            self.errorCallback?("Failed to setup audio engine.")
        }
    }

    private func recognitionHandler(audioEngine: AVAudioEngine?, result: SFSpeechRecognitionResult?, error: Error?) {
        // let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil

        if receivedError {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask = nil
        }

        if let result = result {
            print("Result: \(result.bestTranscription.formattedString)")
            self.resultCallback?(result.bestTranscription.formattedString)
        }

        if let error = error {
            print("Recognition error: \(error)")
            self.errorCallback?(error.localizedDescription)
        }
    }

    func stopRecording() {
        if let audioEngine = audioEngine {
          audioEngine.inputNode.removeTap(onBus: 0)
          audioEngine.stop()
        }
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
    }
}
