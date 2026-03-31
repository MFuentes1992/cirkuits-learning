//
//  SpeechRecognizer.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 16/11/25.
//
import Foundation
import AVFoundation
import Speech
import os

/// A modern speech recognizer that uses async/await and delegation pattern
/// to decouple speech recognition from game state management.
@MainActor
class SpeechRecognizer: NSObject {
    
    // MARK: - Types
    
    enum RecognizerError: Error, LocalizedError {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        case alreadyRecording
        
        var errorDescription: String? {
            switch self {
            case .nilRecognizer: 
                return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: 
                return "Not authorized to recognize speech"
            case .notPermittedToRecord: 
                return "Not permitted to record audio"
            case .recognizerIsUnavailable: 
                return "Recognizer is unavailable"
            case .alreadyRecording:
                return "Already recording"
            }
        }
    }
    
    enum RecognitionState: Equatable {
        case idle
        case recording
        case processing
        case error(Error)
        
        static func == (lhs: RecognitionState, rhs: RecognitionState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.recording, .recording), (.processing, .processing):
                return true
            case (.error, .error):
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    private let recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let logger = Logger(subsystem: "com.cirkuits.igniter", category: "SpeechRecognizer")
    
    private(set) var currentState: RecognitionState = .idle
    private(set) var currentTranscript: String = ""
    
    /// Callback invoked when transcription updates
    var onTranscriptionUpdate: ((String) -> Void)?
    
    /// Callback invoked when recognition state changes
    var onStateChange: ((RecognitionState) -> Void)?
    
    // MARK: - Initialization
    
    init(locale: Locale = .current) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        
        // Monitor recognizer availability
        self.recognizer?.delegate = self
    }
    
    deinit {
        // Cleanup needs to happen synchronously in deinit
        // We can't call @MainActor methods, so we do basic cleanup directly
        // The task, audioEngine, and request will be deallocated automatically
    }
    
    // MARK: - Authorization
    
    /// Request authorization for speech recognition and microphone access
    func requestAuthorization() async throws {
        // Check speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            logger.error("Speech recognition not authorized: \(String(describing: speechStatus))")
            throw RecognizerError.notAuthorizedToRecognize
        }
        
        // Check microphone authorization
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard audioStatus else {
            logger.error("Microphone access not authorized")
            throw RecognizerError.notPermittedToRecord
        }
        
        logger.info("Speech recognition and microphone authorized")
    }
    
    /// Check if currently authorized
    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    // MARK: - Recording Control
    
    /// Start speech recognition
    func startRecording() async throws {
        guard currentState != .recording else {
            throw RecognizerError.alreadyRecording
        }
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerIsUnavailable
        }
        
        // Ensure we have authorization
        guard isAuthorized else {
            throw RecognizerError.notAuthorizedToRecognize
        }
        
        do {
            // Setup audio engine and request
            let (engine, request) = try await prepareEngine()
            self.audioEngine = engine
            self.request = request
            
            updateState(.recording)
            
            // Start recognition task
            self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    
                    if let error = error {
                        self.logger.error("Recognition error: \(error.localizedDescription)")
                        self.updateState(.error(error))
                        self.stop()
                        return
                    }
                    
                    if let result = result {
                        let transcript = result.bestTranscription.formattedString
                        self.currentTranscript = transcript
                        self.onTranscriptionUpdate?(transcript)
                        
                        if result.isFinal {
                            self.logger.info("Final transcript: \(transcript)")
                            self.stop()
                        }
                    }
                }
            }
            
            logger.info("Speech recognition started")
            
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            updateState(.error(error))
            stop()
            throw error
        }
    }
    
    /// Stop speech recognition
    func stop() {
        task?.cancel()
        task = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        request?.endAudio()
        request = nil
        
        updateState(.idle)
        logger.info("Speech recognition stopped")
    }
    
    /// Pause recognition temporarily
    func pause() {
        audioEngine?.pause()
        updateState(.processing)
    }
    
    /// Resume recognition
    func resume() throws {
        guard let audioEngine = audioEngine else {
            throw RecognizerError.recognizerIsUnavailable
        }
        
        try audioEngine.start()
        updateState(.recording)
    }
    
    // MARK: - Private Helpers
    
    private func prepareEngine() async throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        
        // Configure request for game use case
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation  // Better for single words
        request.requiresOnDeviceRecognition = false  // Allow cloud if needed
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Setup audio tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func updateState(_ newState: RecognitionState) {
        currentState = newState
        onStateChange?(newState)
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available {
                logger.warning("Speech recognizer became unavailable")
                stop()
            }
        }
    }
}
