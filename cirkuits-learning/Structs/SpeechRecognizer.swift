//
//  Microphone.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 16/11/25.
//
import Foundation
import AVFoundation
import Speech

class SpeechRecognizer {
    public enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        public var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    var transcript = ""
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    private var gameState: GameState?
    
    init(gameState: GameState) {
        recognizer = SFSpeechRecognizer()
        self.gameState = gameState
        guard recognizer != nil else {
            print(RecognizerError.nilRecognizer)
            return
        }
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                print(error)
            }
        }
    }
    
    func startRecording() throws {
        do {
            let (audioEngine, request) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            
            guard let recognizer = self.recognizer else {
                throw RecognizerError.recognizerIsUnavailable
            }
            self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else {
                    return
                }
                
                if let error = error {
                    print("AVAudio engine error:\(error)")
                    self.reset()
                    return
                }
                
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    gameState?.capturedAnser = newText
                   print("Voice captured:\(newText)")
                    // True when engine is stopped
                    if result.isFinal {
                        self.reset()
                    }
                }

            }
        } catch {
            self.reset()
        }
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.addsPunctuation = true
        request.taskHint = .dictation
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    func stopTranscribing() {
        reset()
    }
    
    func reset() {
        task?.cancel()
        task = nil
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        transcript = ""
    }
        
}
