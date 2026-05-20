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
    private var gameState: GameState!
    private var hud: IgniterHUD
    private var WordFoos = [WordFoo]()
    private var spRecTaskHint: SFSpeechRecognitionTaskHint
    private var speechRecognition: SpeechRecognizer
    // -- Telemetry
    let logger = Logger(subsystem: "com.cirkuits.igniter", category: "GameLoop")
    
    // -- Local Game Track
    private var score: Double = 0
    private var combo: Int = 0

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
    
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
        cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: 19.5/9,
            nearZ: 1.0,
            farZ: 1000.0)
        let wordsPerStage = igniterStageMapping(stage: String(gameState.Stage)) ?? 1
        for i in stride(from: 0, to: wordBank.count - 1, by: wordsPerStage) {
            let slice = wordBank[i...(i+(wordsPerStage - 1))]
            let sentence = createSentence(bank: slice.map({ String($0) }))
            WordFoos.append(WordFoo(Word: sentence, Reward: Int.random(in: 1...9)))
        }
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device, screenWidth: Float(view.bounds.width))
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
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
        score += Double(reward)
        currentFooIndex = (currentFooIndex + 1) % WordFoos.count //
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
        gameState.AnswersBucket = []
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
                    timeToAnswer = 0
                    nextFoo(reward: 0)
                    streakChain = 0
                    hud.incrementCombo(streakChain)
                    gameState.PlayerState = .Idle
                    wordStartSec = gameState.Timer.getElapsedTime()
                }
                
                // --- Evaluate if correct answer
                let goal = sanitizeText(text: WordFoos[currentFooIndex].Word)
                let rawSentence = createSentence(bank: gameState.AnswersBucket)
                let answer = sanitizeText(text: rawSentence)
                logger.info("Comparisson -> goal: \(goal) - answer: \(answer)")
                let isCorrect = answer == goal
                logger.info("Is correct: \(isCorrect)")
                
                if isCorrect {
                    gameState.PlayerState = .Idle
                    nextFoo(reward: WordFoos[currentFooIndex].Reward)
                    resetTimers()
                    streakChain += 1
                    hud.incrementCombo(streakChain)
                    wordStartSec = gameState.Timer.getElapsedTime()
                    hud.showCorrectFeedback()
                }
            case .Idle:
                let wordElapsedSec = gameState.Timer.getElapsedTime() - wordStartSec
                gameElapsedTime = gameState.Timer.getElapsedTime()
                if wordElapsedSec > gameState.WordTimeToLive {
                    nextFoo(reward: 0)
                    resetTimers()
                    streakChain = 0
                    hud.incrementCombo(streakChain)
                    wordStartSec = gameState.Timer.getElapsedTime()
                }
            }
            if  gameElapsedTime >= gameState.LevelDuration {
                gameState.HighScore = gameState.Score
                requestScene(.GameOver)
            }
            hud.updateTimerDisplay(gameElapsedTime: gameElapsedTime)
            hud.updateHudScore(score: Int(score))
            if streakChain == gameState.MaxStreak  {
                if gameState.Combo == 3 {
                    score *= 2.2
                    gameState.Combo = 0
                } else {
                    score *= 1.5
                }
                streakChain = 0
                gameState.Combo = gameState.Combo + 1
            }
            
            gameState.Score = Int(score)
            gameState.Streak = streakChain
        }
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
}
