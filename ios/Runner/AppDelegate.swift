import Flutter
import UIKit
import Foundation
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let speechRecognitionChannel = "speech_recognition_channel"
  private let speechRecognitionEventChannel = "speech_recognition_stream"
  private let speechService = SpeechRecognitionService()
  private var flutterResult: FlutterResult?
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let binaryMessenger = controller.binaryMessenger
    let channel = FlutterMethodChannel(name: speechRecognitionChannel, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      self.handleMethodCall(call, result: result)
    }

    // Event Channel untuk hasil streaming
    let eventChannel = FlutterEventChannel(name: speechRecognitionEventChannel, binaryMessenger: controller.binaryMessenger)
    eventChannel.setStreamHandler(self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    flutterResult = result
    self.eventSink?("AppDelegate: Method call: \(call.method)") 

    switch call.method {
    case "startRecording":

      self.eventSink?("AppDelegate: startRecording called") 
      speechService.startRecording(
        result: { text in
          // result(text)

          print("AppDelegate: Speech recognition result: \(text)")
          self.eventSink?(text)
          // self.flutterResult = nil
        },
        error: { error in
          result(FlutterError(code: "SPEECH_RECOGNITION_ERROR", message: error, details: nil))
          self.flutterResult = nil
        }
      )

      result(nil)
      self.flutterResult = nil
    case "stopRecording":
      self.eventSink?("AppDelegate: stopRecording called")
      speechService.stopRecording()
      result(nil) 
      self.flutterResult = nil
    default:
      result(FlutterMethodNotImplemented)
      self.flutterResult = nil
    }
  }
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
          events("stream connected")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
