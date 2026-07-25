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
    private var taskHint: SFSpeechRecognitionTaskHint
    private let logger = Logger(subsystem: "com.cirkuits.igniter", category: "SpeechRecognizer")
    
    private(set) var currentState: RecognitionState = .idle
    private(set) var currentTranscript: String = ""
    
    /// Callback invoked when transcription updates
    var onTranscriptionUpdate: ((String) -> Void)?
    
    /// Callback invoked when recognition state changes
    var onStateChange: ((RecognitionState) -> Void)?

    /// Callback invoked when the active audio input device changes
    /// (e.g. built-in mic ↔ Bluetooth headset)
    var onAudioInputChange: ((AudioInputType) -> Void)?

    /// Observer token for audio route change notifications.
    private var routeObserver: NSObjectProtocol?

    /// The audio input that will capture the player's voice: an external mic
    /// (Bluetooth/wired headset) when one is attached, otherwise the built-in
    /// mic. Mirrors `selectPreferredInput`.
    ///
    /// This inspects `availableInputs` (attached input hardware) rather than
    /// `currentRoute` — the active route only switches to an external mic once
    /// the session is activated during recording, so a route check reports the
    /// built-in mic on the menu even when a headset is connected. Requires a
    /// record-capable category to be set (see `refreshAudioInput` /
    /// `prepareEngine`), otherwise `availableInputs` is nil and we report
    /// built-in.
    var currentInputType: AudioInputType {
        let hasExternal = AVAudioSession.sharedInstance().availableInputs?
            .contains { $0.portType != .builtInMic } ?? false
        return hasExternal ? .external : .builtIn
    }

    // MARK: - Initialization

    init(taskHint: SFSpeechRecognitionTaskHint, locale: Locale = .current) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
        self.taskHint = taskHint
        super.init()

        // Monitor recognizer availability
        self.recognizer?.delegate = self

        // Monitor audio route changes (built-in mic ↔ Bluetooth headset, etc.)
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.notifyAudioInputChange()
            }
        }
    }

    deinit {
        // Cleanup needs to happen synchronously in deinit
        // We can't call @MainActor methods, so we do basic cleanup directly
        // The task, audioEngine, and request will be deallocated automatically
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
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

            startRecognitionTask(with: request)

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

    /// Restart recognition without tearing down the audio engine.
    /// Used to keep listening across `isFinal` finalizations so the player
    /// can keep speaking within a single answer window.
    func restart() {
        guard let recognizer, recognizer.isAvailable else {
            logger.warning("Cannot restart: recognizer unavailable")
            stop()
            return
        }
        guard let audioEngine, audioEngine.isRunning else {
            logger.warning("Cannot restart: audio engine not running")
            stop()
            return
        }

        task?.cancel()
        task = nil
        request?.endAudio()

        currentTranscript = ""

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let newRequest = makeRequest()
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            newRequest.append(buffer)
        }
        self.request = newRequest

        startRecognitionTask(with: newRequest)
        logger.info("Speech recognition restarted")
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
    
    /// Configure the audio session for input monitoring *without* starting the
    /// engine, then report the currently-active input. Lets non-recording UI —
    /// e.g. the menu — show which mic will capture the player's voice, reusing
    /// the same route selection and detection used during recording.
    func refreshAudioInput() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement,
                                         options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
        } catch {
            logger.warning("Failed to configure session for input monitoring: \(error.localizedDescription)")
        }

        selectPreferredInput(audioSession)
        logCurrentInput(audioSession)
        notifyAudioInputChange()
    }

    // MARK: - Private Helpers

    private func prepareEngine() async throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let taskHint = self.taskHint

        // Activating the audio session and starting the engine are synchronous
        // calls that can block for a noticeable time — in particular,
        // `setActive`/`setPreferredInput` negotiate the hardware route, which is
        // slow when switching to a Bluetooth (HFP) headset. Run them off the
        // main thread so the game's first frames (the word + fire border) render
        // immediately instead of waiting on audio startup.
        let (audioEngine, request) = try await Task.detached(priority: .userInitiated) {
            let audioEngine = AVAudioEngine()

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = taskHint
            request.requiresOnDeviceRecognition = false

            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Prefer an external input (Bluetooth/wired headset) when attached.
            if let external = audioSession.availableInputs?.first(where: { $0.portType != .builtInMic }) {
                try? audioSession.setPreferredInput(external)
            }

            // Setup audio tap
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            return (audioEngine, request)
        }.value

        logCurrentInput(AVAudioSession.sharedInstance())
        notifyAudioInputChange()

        return (audioEngine, request)
    }

    /// Reports the current audio input type to observers.
    private func notifyAudioInputChange() {
        let inputType = currentInputType
        logger.info("Active audio input type: \(String(describing: inputType))")
        onAudioInputChange?(inputType)
    }

    private func selectPreferredInput(_ audioSession: AVAudioSession) {
        guard let inputs = audioSession.availableInputs else {
            logger.info("No available inputs reported")
            return
        }
        if let external = inputs.first(where: { $0.portType != .builtInMic }) {
            do {
                try audioSession.setPreferredInput(external)
                logger.info("Preferred input set to external: \(external.portName) [\(external.portType.rawValue)]")
            } catch {
                logger.warning("Failed to set preferred input \(external.portName): \(error.localizedDescription)")
            }
        } else {
            logger.info("No external input available; using built-in")
        }
    }

    private func logCurrentInput(_ audioSession: AVAudioSession) {
        let inputs = audioSession.currentRoute.inputs
        guard let input = inputs.first else {
            logger.info("Audio input: <none reported by AVAudioSession>")
            return
        }
        logger.info("Audio input: \(input.portName) [\(input.portType.rawValue)] uid=\(input.uid)")
        if let ds = input.selectedDataSource {
            logger.info("Data source: \(ds.dataSourceName) orientation=\(String(describing: ds.orientation))")
        }
        if inputs.count > 1 {
            let extras = inputs.dropFirst().map { "\($0.portName) [\($0.portType.rawValue)]" }.joined(separator: ", ")
            logger.info("Additional route inputs: \(extras)")
        }
    }

    private func makeRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = taskHint // One of: unspecified, dictation, search, confirmation
        request.requiresOnDeviceRecognition = false
        return request
    }

    private func startRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest) {
        guard let recognizer else { return }
        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.logger.error("Recognition error: \(error.localizedDescription)")
                    self.updateState(.error(error))
                    self.stop()
                    return
                }

                if let result {
                    let transcript = result.bestTranscription.formattedString
                    self.currentTranscript = transcript
                    self.onTranscriptionUpdate?(transcript)

                    if result.isFinal {
                        self.logger.info("Final transcript: \(transcript) — restarting")
                        self.stop()
                    }
                }
            }
        }
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
