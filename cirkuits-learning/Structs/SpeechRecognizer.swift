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

    /// Incremented every time a recognition task is started. Callbacks carry the
    /// generation they were created with and are ignored once it goes stale, so
    /// a cancelled task's trailing callback can't tear down its replacement.
    private var taskGeneration: UInt64 = 0

    /// Consecutive recognition failures with no successful result in between.
    /// Bounded so a genuinely broken session gives up instead of restarting
    /// forever.
    private var consecutiveFailures = 0
    private static let maxConsecutiveFailures = 3
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
        ) { [weak self] note in
            let reasonValue = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self else { return }
                let reason = reasonValue
                    .flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
                    .map { String(describing: $0) } ?? "unknown"
                self.dumpAudioDiagnostics("route-change(\(reason))")
                self.notifyAudioInputChange()
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
            self.consecutiveFailures = 0

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
        // Retire the current generation so the cancelled task's trailing
        // callback can't reopen a session we're tearing down.
        taskGeneration &+= 1
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
        let probe = AudioLevelProbe(sampleRate: recordingFormat.sampleRate, logger: logger)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            newRequest.append(buffer)
            probe.observe(peak: SpeechRecognizer.peakAmplitude(buffer),
                          frames: Int(buffer.frameLength))
        }
        self.request = newRequest

        startRecognitionTask(with: newRequest)
        logger.info("Speech recognition restarted")
        dumpAudioDiagnostics("restart")
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
            try Self.configureSessionCategory(audioSession)
        } catch {
            logger.warning("Failed to configure session for input monitoring: \(error.localizedDescription)")
        }

        selectPreferredInput(audioSession)
        logCurrentInput(audioSession)
        dumpAudioDiagnostics("refresh-audio-input")
        notifyAudioInputChange()
    }

    // MARK: - Audio Session Configuration

    /// Applies the category/mode/options used for recording. Shared by every
    /// entry point so the three call sites can't drift apart.
    nonisolated static func configureSessionCategory(_ session: AVAudioSession) throws {
        try session.setCategory(.playAndRecord, mode: .measurement,
                                options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
    }

    /// Routes capture to an external mic (Bluetooth/wired headset) when one is
    /// attached. Best-effort: falls through to the built-in mic on failure.
    @discardableResult
    nonisolated static func selectExternalInput(_ session: AVAudioSession) -> AVAudioSessionPortDescription? {
        guard let external = session.availableInputs?.first(where: { $0.portType != .builtInMic }) else {
            return nil
        }
        try? session.setPreferredInput(external)
        return external
    }

    /// Activates the shared audio session ahead of recording so the hardware
    /// route is already negotiated by the time the game starts.
    ///
    /// Bluetooth HFP link setup costs ~1.5s, and it is `setActive(true)` that
    /// triggers it — not `setCategory`. Without this the cost lands inside
    /// `prepareEngine` when the Igniter scene appears, and the player spends the
    /// first word unable to answer. Calling this during the countdown spends
    /// that time while nothing is being asked of them.
    ///
    /// Safe to call from anywhere: `AVAudioSession` is process-wide, so warming
    /// it settles the route for whichever `SpeechRecognizer` records later. Runs
    /// off the main thread because the activation call blocks.
    nonisolated static func prewarmAudioSession() {
        Task.detached(priority: .userInitiated) {
            let logger = Logger(subsystem: "com.cirkuits.igniter", category: "SpeechRecognizer")
            let session = AVAudioSession.sharedInstance()
            let start = Date()
            do {
                try configureSessionCategory(session)
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                let external = selectExternalInput(session)
                let elapsed = Date().timeIntervalSince(start)
                logger.notice("""
                    [prewarm] session active in \(String(format: "%.3f", elapsed), privacy: .public)s \
                    input=\(external?.portName ?? "<built-in>", privacy: .public)
                    """)
            } catch {
                logger.warning("[prewarm] failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Private Helpers

    /// Peak amplitude of a captured buffer, 0...1. Used only by the audio-level
    /// probe below — lets us distinguish "wrong mic selected" from "right mic,
    /// but no signal reaching us".
    private nonisolated static func peakAmplitude(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channels = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        var peak: Float = 0
        for channel in 0..<Int(buffer.format.channelCount) {
            let samples = channels[channel]
            for frame in 0..<frames {
                peak = max(peak, abs(samples[frame]))
            }
        }
        return peak
    }

    private func prepareEngine() async throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let taskHint = self.taskHint
        let logger = self.logger

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

            // Configure audio session. If `prewarmAudioSession()` already ran
            // (see `CountDownScene`), the session is active and the Bluetooth
            // route is settled, so this costs close to nothing.
            let sessionStart = Date()
            let audioSession = AVAudioSession.sharedInstance()
            try SpeechRecognizer.configureSessionCategory(audioSession)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            SpeechRecognizer.selectExternalInput(audioSession)
            let sessionElapsed = Date().timeIntervalSince(sessionStart)
            logger.notice("""
                [engine-start] session ready in \
                \(String(format: "%.3f", sessionElapsed), privacy: .public)s
                """)

            // Setup audio tap
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // Rolling peak, reported ~1x/sec so the log stays readable. A steady
            // 0.000 while speaking means the tap is attached to a mic that isn't
            // hearing anything — a different failure than the wrong route.
            let probe = AudioLevelProbe(sampleRate: recordingFormat.sampleRate, logger: logger)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
                probe.observe(peak: SpeechRecognizer.peakAmplitude(buffer),
                              frames: Int(buffer.frameLength))
            }

            audioEngine.prepare()
            try audioEngine.start()

            return (audioEngine, request)
        }.value

        logCurrentInput(AVAudioSession.sharedInstance())
        dumpAudioDiagnostics("engine-started", engine: audioEngine)
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

    /// Dumps everything needed to tell whether the headset mic is *actually*
    /// capturing, as opposed to merely being attached. Logged at `.notice` so it
    /// survives a default `log stream` (unlike the `.info` calls elsewhere).
    ///
    /// Read it as: `available` is attached hardware, `ROUTE` is what is really
    /// capturing. They disagree when the session fell back to the built-in mic.
    /// `tapFormat` corroborates — Bluetooth HFP input runs at 8k/16k, the
    /// built-in mic at 48k, so a 48k tap on a headset route means the engine
    /// grabbed `inputNode` before the route settled.
    func dumpAudioDiagnostics(_ context: String, engine: AVAudioEngine? = nil) {
        let engine = engine ?? audioEngine
        let session = AVAudioSession.sharedInstance()

        let available = (session.availableInputs ?? [])
            .map { "\($0.portName)[\($0.portType.rawValue)]" }
            .joined(separator: ", ")
        let route = session.currentRoute.inputs
            .map { "\($0.portName)[\($0.portType.rawValue)]" }
            .joined(separator: ", ")
        let preferred = session.preferredInput
            .map { "\($0.portName)[\($0.portType.rawValue)]" } ?? "<none>"

        logger.notice("""
            [\(context, privacy: .public)] \
            available={\(available, privacy: .public)} \
            ROUTE={\(route.isEmpty ? "<none>" : route, privacy: .public)} \
            preferred=\(preferred, privacy: .public) \
            category=\(session.category.rawValue, privacy: .public) \
            mode=\(session.mode.rawValue, privacy: .public) \
            sessionSampleRate=\(session.sampleRate) \
            engineRunning=\(engine?.isRunning ?? false)
            """)

        if let inputNode = engine?.inputNode {
            let format = inputNode.outputFormat(forBus: 0)
            logger.notice("""
                [\(context, privacy: .public)] \
                tapFormat=\(format.sampleRate)Hz ch=\(format.channelCount)
                """)
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

        taskGeneration &+= 1
        let generation = taskGeneration

        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                // A cancelled task still delivers a trailing callback. Ignore it
                // if we've already moved on, otherwise it would tear down the
                // session that replaced it.
                guard generation == self.taskGeneration else { return }

                if let error {
                    self.handleRecognitionFailure(error)
                    return
                }

                if let result {
                    let transcript = result.bestTranscription.formattedString
                    self.currentTranscript = transcript
                    self.consecutiveFailures = 0
                    self.onTranscriptionUpdate?(transcript)

                    if result.isFinal {
                        // The recognizer finalizes after a pause in speech, which
                        // in this game happens after every single answer. Keep
                        // the engine up and start a fresh request so the player
                        // can answer the next word.
                        self.logger.info("Final transcript: \(transcript) — restarting")
                        self.restart()
                    }
                }
            }
        }
    }

    /// Recognition errors are mostly routine here — "no speech detected" fires
    /// whenever the player stays quiet through a word. Recover by starting a new
    /// request on the still-running engine rather than ending the session, and
    /// only give up once failures repeat with no successful result between them.
    private func handleRecognitionFailure(_ error: Error) {
        consecutiveFailures += 1
        logger.error("""
            Recognition error (\(self.consecutiveFailures)/\(Self.maxConsecutiveFailures)): \
            \(error.localizedDescription)
            """)

        guard consecutiveFailures < Self.maxConsecutiveFailures,
              let audioEngine, audioEngine.isRunning else {
            logger.error("Giving up on recognition after repeated failures")
            updateState(.error(error))
            stop()
            return
        }

        restart()
    }

    private func updateState(_ newState: RecognitionState) {
        currentState = newState
        onStateChange?(newState)
    }
}

// MARK: - Audio Level Probe

/// Accumulates the peak amplitude of captured audio and logs it about once per
/// second. Diagnostic only — it answers "is the selected mic actually hearing
/// anything?", which the route information alone can't tell us.
///
/// `observe(peak:frames:)` is called from the real-time audio thread, so the
/// mutable state is guarded by a lock and the work per buffer is kept trivial.
private final class AudioLevelProbe: @unchecked Sendable {
    private let sampleRate: Double
    private let logger: Logger
    private let lock = NSLock()
    private var peak: Float = 0
    private var framesSinceReport = 0

    init(sampleRate: Double, logger: Logger) {
        self.sampleRate = sampleRate
        self.logger = logger
    }

    func observe(peak bufferPeak: Float, frames: Int) {
        lock.lock()
        peak = max(peak, bufferPeak)
        framesSinceReport += frames

        guard sampleRate > 0, Double(framesSinceReport) >= sampleRate else {
            lock.unlock()
            return
        }

        let reportedPeak = peak
        peak = 0
        framesSinceReport = 0
        lock.unlock()

        logger.notice("Audio level peak=\(String(format: "%.4f", reportedPeak), privacy: .public)")
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
