//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import os
import Speech
import MetalKit

@MainActor
class IgniterScene: SceneProtocol {
    private var wordRenderer: WordRenderer!
    private var cameraSettings: CameraSettings!
    private var camera: Camera!
    private var device: MTLDevice!
    private var currentFooIndex: Int
    private var timeToAnswer: Double
    private var wordTimeToLive: Double
    private var gameElapsedTime: Double
    private var streakChain: Int
    private var currentAnswerWindow: Double
    private var wordStartSec: Double
    private var checkMarkTime: Double
    private var switchTime: Double
    private var gameState: GameState!
    private var hud: IgniterHUD
    private var WordFoos = [WordFoo]()
    private var spRecTaskHint: SFSpeechRecognitionTaskHint
    private var speechRecognition: SpeechRecognizer
    // -- Telemetry
    let logger = Logger(subsystem: "com.cirkuits.igniter", category: "GameLoop")
    
    // -- Local Game Track
    private var score: Double = 0

    /// Score multiplier by number of completed streaks. Each streak of
    /// `GameState.StreakGoal` consecutive correct answers moves the player one
    /// tier up; a wrong answer drops them back to the first. Capped so a long
    /// perfect run can't run away with the scoreboard.
    private static let streakMultipliers: [Double] = [1.0, 1.5, 2.0, 2.5, 3.0]

    /// Multiplier applied to the reward for the word being scored right now.
    ///
    /// Reads the streak count *before* the current answer is folded in, so a
    /// completed streak raises the multiplier for the words that follow it
    /// rather than retroactively paying out the streak that earned it.
    private var scoreMultiplier: Double {
        Self.streakMultipliers[min(streakChain, Self.streakMultipliers.count - 1)]
    }

    /// How long the correct / missed feedback holds before the next word.
    private let feedbackDuration: Double = 1.1
    /// Plays over the feedback window instead of the word just vanishing.
    private let exitAnimation = WordExitAnimation()

    /// Fraction of the visible frustum the word may fill, leaving a border.
    private let framingMargin: Float = 0.85
    /// Aspect and HUD word area (top, bottom) the current layout was fitted
    /// for; a change triggers a re-layout.
    private var fittedFor: SIMD3<Float>?

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero

    // Official Igniter backdrop. Sits behind the transparent Metal view (in the
    // root view, above the shared SwirlPatternView) so the 3D letters render on
    // top of it. Removed on teardown so other scenes keep the shared background.
    private weak var backgroundView: UIImageView?
    
    let wordBank: [String] = [
        "I", "am",
        "You", "are",
        "He", "is",
        "She", "is",
        "It", "is",
        "We", "are",
        "They", "are",
        "We", "won",
        "I", "see",
        "She", "is",
        "He", "is",
        "I", "am",
        "You", "kind",
        "We", "are",
        "They", "are"
    ]

    private var gameOverTriggered = false
    private var requestScene: (GameScenes) -> Void

    init(device: MTLDevice, view: MTKView, gameState: GameState,
         currentFooIndex: Int = 0, requestScene: @escaping (GameScenes) -> Void) {
        self.device = device
        self.gameState = gameState
        self.requestScene = requestScene
        self.currentFooIndex = currentFooIndex
        self.timeToAnswer = 0
        self.wordTimeToLive = 0
        self.currentAnswerWindow = 0
        self.gameElapsedTime = 0
        self.wordStartSec = 0
        self.streakChain = 0
        self.checkMarkTime = 0
        self.switchTime = 0
        self.spRecTaskHint = .confirmation
        self.speechRecognition = SpeechRecognizer(taskHint: spRecTaskHint)
        
        hud = IgniterHUD(parentView: view, gameState: gameState, speechRecognizer: speechRecognition)
        buildInitialScene(view: view)
        setupSpeechRecognition()
    }
    
    private func setupSpeechRecognition() {
        // Configure callbacks
        speechRecognition.onTranscriptionUpdate = { [weak self] transcript in
            guard let self = self else { return }
            self.gameState.CapturedAnswer = transcript
            self.gameState.PlayerState = .Speaking
        }
        
        speechRecognition.onStateChange = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .idle:
                self.gameState.AnswersBucket = []
                self.gameState.PlayerState = .Idle
            case .recording:
                self.logger.info("Speech recognition started")
            case .processing:
                self.logger.info("Processing speech...")
            case .error(let error):
                self.logger.error("Speech recognition error: \(error.localizedDescription)")
            }
        }
        
        // Request authorization and start recording
        Task {
            do {
                try await speechRecognition.requestAuthorization()
                try await speechRecognition.startRecording()
                logger.info("Speech recognition initialized successfully")
            } catch {
                logger.error("Failed to initialize speech recognition: \(error.localizedDescription)")
            }
        }
    }
    
    func buildInitialScene(view: MTKView) {
        installBackground(view: view)
        cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: viewAspect(view) ?? 9/19.5,
            nearZ: 1.0,
            farZ: 1000.0)
        let wordsPerStage = igniterStageMapping(stage: String(gameState.Stage)) ?? 1
        for i in stride(from: 0, to: wordBank.count - 1, by: wordsPerStage) {
            let slice = wordBank[i...(i+(wordsPerStage - 1))]
            let sentence = createSentence(bank: slice.map({ String($0) }))
            WordFoos.append(WordFoo(Word: sentence, Reward: Int.random(in: 1...9)))
        }
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device)
        fitLayout(view: view)
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]

        // Leave a beat at the end of the window so the next word doesn't pop in
        // the same frame the last letter clears the camera.
        exitAnimation.maxTotalDuration = Float(feedbackDuration) - 0.1
        wordRenderer.letterTransformModifier = { [weak self] index, letter, layout in
            guard let self else { return layout }
            let toEye = self.camera.settings.eye - self.camera.settings.center
            return self.exitAnimation.transform(
                index: index, letter: letter, layout: layout,
                toEye: normalize(toEye), travel: simd_length(toEye) + 60)
        }
    }

    /// Width over height of the drawable, falling back to the view's bounds
    /// before the drawable has been sized. Nil if neither is known yet.
    private func viewAspect(_ view: MTKView) -> Float? {
        let size = view.drawableSize.height > 0 ? view.drawableSize : view.bounds.size
        guard size.height > 0 else { return nil }
        return Float(size.width / size.height)
    }

    /// What the layout depends on: the view's aspect and the HUD's word area.
    private func fitKey(_ view: MTKView) -> SIMD3<Float>? {
        guard let aspect = viewAspect(view) else { return nil }
        let area = hud.wordArea
        return SIMD3<Float>(aspect, Float(area.top), Float(area.bottom))
    }

    /// Height of the frustum slice at the text plane (z = 0), in world units.
    private var visibleHeight: Float {
        let distance = simd_length(camera.settings.eye - camera.settings.center)
        return 2 * distance * tan(radians_from_degrees(camera.settings.fovDegrees) / 2)
    }

    /// Wraps and scales words to the frustum width and the HUD's word area, so
    /// a phrase always fits between the progress dots and the streak gauge.
    private func fitLayout(view: MTKView) {
        guard let key = fitKey(view) else { return }
        fittedFor = key
        let aspect = key.x
        camera.settings.aspectRatio = aspect

        let screenHeight = Float(view.bounds.height)
        let areaFraction = screenHeight > 0 ? (key.z - key.y) / screenHeight : 1
        wordRenderer.layoutMode = .wrapped(
            maxWidth: visibleHeight * aspect * framingMargin,
            maxHeight: visibleHeight * min(framingMargin, areaFraction))
    }

    /// Slides the camera straight up or down so the word's top edge lands on
    /// the top of the HUD's word area. Only the height changes, so the exit
    /// animation still flies straight at the viewer.
    private func frameWord(view: MTKView) {
        let screenHeight = Float(view.bounds.height)
        guard let bounds = wordRenderer.wordBounds, screenHeight > 0 else { return }
        // Where the area's top sits in normalised device coordinates (+1 = top).
        let areaTopNDC = 1 - 2 * Float(hud.wordArea.top) / screenHeight
        let y = bounds.max.y - visibleHeight / 2 * areaTopNDC
        camera.settings.eye.y = y
        camera.settings.center.y = y
    }
    
    /// Places the official Igniter backdrop directly beneath the transparent
    /// Metal view, so the 3D letters render on top of it.
    private func installBackground(view: MTKView) {
        guard let container = view.superview else { return }
        let imageView = ScreenAsset.backgroundView(ScreenAsset.igniterBackground,
                                                   frame: container.bounds)
        container.insertSubview(imageView, belowSubview: view)
        backgroundView = imageView
    }

    deinit {
        // Scene teardown only clears the Metal view's subviews; our backdrop
        // lives in the root view, so remove it explicitly.
        backgroundView?.removeFromSuperview()
    }

    func play() {}
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        if gesture.state == .began {
            lastPanLocation = location
        } else if gesture.state == .changed {
            let delta = CGPoint(x: location.x - lastPanLocation.x, y: location.y - lastPanLocation.y)
            lastPanLocation = location
        }
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }
    
    func nextFoo(reward: Int) {
        let earned = Double(reward) * scoreMultiplier
        if reward > 0 {
            logger.info("""
                Scored \(reward) x\(self.scoreMultiplier, format: .fixed(precision: 1)) \
                = \(earned, format: .fixed(precision: 1)) (streak \(self.streakChain))
                """)
            hud.showScoreGain(Int(earned.rounded()))
        }
        score += earned
        currentFooIndex = (currentFooIndex + 1) % WordFoos.count //
        exitAnimation.stop()
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
        gameState.AnswersBucket = []
    }
    
    /// Starts the letters flying out on the first frame of a feedback window.
    private func startExitIfNeeded() {
        guard !exitAnimation.isRunning else { return }
        exitAnimation.start(letterCount: WordFoos[currentFooIndex].Word.count)
    }

    func resetTimers() {
        wordStartSec = gameState.Timer.getElapsedTime()
        timeToAnswer = 0
    }
    
    // -- Encode is called by update.
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        if gameState.CurrentState == .initializing {
            gameState.Timer.StartTime = Date().timeIntervalSince1970
            gameElapsedTime = gameState.Timer.getElapsedTime()
            gameState.CurrentState = .running
        }
        
        if gameState.CurrentState == .running {
            logger.info("Player state: \(self.gameState.PlayerState == .Speaking ? "Speaking" : "Idle") ")
            logger.info("Game elapsed time: \(self.gameElapsedTime)")
            logger.info("Objective word: \(self.WordFoos[self.currentFooIndex].Word)")
            switch gameState.PlayerState {
            case .Speaking:
                timeToAnswer = gameState.Timer.getElapsedTime() - wordStartSec
                //  -- No updates on elapsed time
                if timeToAnswer >= gameState.WordTimeToAnswer {
                    hud.showIncorrectFeedback()
                    gameState.PlayerState = .Wrong
                    switchTime = gameState.Timer.getElapsedTime()
                }
                
                // --- Evaluate if correct answer
                let goal = sanitizeText(text: WordFoos[currentFooIndex].Word)
                let rawSentence = createSentence(bank: gameState.AnswersBucket)
                let answer = sanitizeText(text: rawSentence)
                logger.info("Comparisson -> goal: \(goal) - answer: \(answer)")
                let isCorrect = answer == goal
                logger.info("Is correct: \(isCorrect)")
                
                if isCorrect && gameState.PlayerState != .Wrong{
                    hud.showCorrectFeedback()
                    gameState.PlayerState = .Correct
                    checkMarkTime = gameState.Timer.getElapsedTime()
                }
            case .Correct:
                startExitIfNeeded()
                if gameState.Timer.getElapsedTime() - checkMarkTime >= feedbackDuration {
                    gameState.PlayerState = .Idle
                    nextFoo(reward: WordFoos[currentFooIndex].Reward)
                    resetTimers()
                    gameState.Combo = gameState.Combo + 1
                    hud.incrementCombo(gameState.Combo)
                    wordStartSec = gameState.Timer.getElapsedTime()
                    speechRecognition.pause()
                }
            case .Wrong:
                startExitIfNeeded()
                if gameState.Timer.getElapsedTime() - switchTime >= feedbackDuration {
                    nextFoo(reward: 0)
                    resetTimers()
                    streakChain = 0
                    gameState.Combo = 0
                    hud.incrementCombo(streakChain)
                    wordStartSec = gameState.Timer.getElapsedTime()
                    gameState.PlayerState = .Idle
                }
            case .Idle:
                let wordElapsedSec = gameState.Timer.getElapsedTime() - wordStartSec
                gameElapsedTime = gameState.Timer.getElapsedTime()
                try? speechRecognition.resume()
                if wordElapsedSec > gameState.WordTimeToLive {
                    switchTime = gameState.Timer.getElapsedTime()
                    hud.showIncorrectFeedback()
                    gameState.PlayerState = .Wrong
                }
            }
            // -- General updating operations ------
            if  gameElapsedTime >= gameState.LevelDuration {
                gameState.HighScore = gameState.Score
                speechRecognition.stop()
                gameState.Timer.stop()
                wordRenderer.cleanUp()
                gameState.CurrentState = .stop
                requestScene(.GameOver)
            }
            hud.updateTimerDisplay(gameElapsedTime: gameElapsedTime)
            hud.updateHudScore(score: Int(score))
            hud.updateProgress(filled: currentFooIndex, total: WordFoos.count)
            if gameState.Combo == gameState.StreakGoal  {
                streakChain = streakChain + 1
                gameState.Combo = 0
            }
            gameState.Score = Int(score)
            gameState.MaxStreak = streakChain
        }
        if let key = fitKey(view), key != fittedFor {
            fitLayout(view: view)
            // Re-assigning re-runs the layout for whatever is on stage.
            wordRenderer.CurrentFoo = wordRenderer.CurrentFoo
        }
        frameWord(view: view)
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
}

