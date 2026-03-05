//
//  SceneA.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//

import simd
import MetalKit

class IgniterScene: SceneProtocol {
    private var wordRenderer: WordRenderer!
    private var cameraSettings: CameraSettings!
    private var camera: Camera!
    private var device: MTLDevice!
    private var timer: TimeController!
    private var currentFooIndex: Int
    private var igniterConfig: LevelConfig!
    private var gameElapsedTime: Double
    private var currentAnswerWindow: Double
    private var gameState: GameState!
    private var WordFoos = [WordFoo]()

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
    
    let wordBank = ["Articulate", "Enthusiastic", "Absolutely", "Particularly", "Extraordinary", "Specifically", "Uniquely", "Passionately", "Radiantly", "Eagerly", "Wednesday", "Comfortable", "Vegetable", "Clothes", "Jewelry", "Schedule", "Chocolate", "Library", "Temperature", "Specific", "Thorough", "Though", "Through", "Thought", "Enough", "Cough", "Bough", "Chaos", "Choir", "Island"]

    init(device: MTLDevice, view: MTKView, gameState: GameState,
         currentFooIndex: Int = 0, isGameOver: Bool = false, isPaused: Bool = false,
         score: Double = 0, strikeCount: Int = 0) {
        self.device = device
        self.gameState = gameState
        self.currentFooIndex = currentFooIndex
        self.gameElapsedTime = 0
        self.currentAnswerWindow = 0
        igniterConfig = LevelConfig(timeWindow: 2, levelDuration: 60, StrikeLimit: 3, maxStreak: 7)
        buildInitialScene(view: view)
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
        
        for word in wordBank {
            WordFoos.append(WordFoo(Word: word, Reward: 1))
        }
        
        
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device, screenWidth: Float(view.bounds.width)) 
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
        timer = TimeController()
        timer.start()
    }
    
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
    
    func NextFoo() {
        currentFooIndex = (currentFooIndex + 1) % WordFoos.count //
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
    }
    
    // -- Encode is called by update.
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        /* timer.update()
        if(gameState.getCurrentState() == .stop) {
            return
        }
                
        if gameState.getCurrentState() == .running || gameState.getCurrentState() == .pause {
            if gameState.getCurrentState() != .pause {
                wordRenderer.update(deltaTime: 1.0/60)
                gameState.decrementTime(time: Double(timer.getTickSeconds())) // This should be on the game state
                gameElapsedTime += Double(timer.getTickSeconds())
                currentAnswerWindow += Double(timer.getTickSeconds())
            }
            wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
        }
        
        
        
        if(currentAnswerWindow < igniterConfig.timeWindow) {
            if wordRenderer.CurrentFoo.Word.lowercased() == gameState.CapturedAnswer.lowercased() {
                gameState.incrementScore(increment: wordRenderer.CurrentFoo.Reward)
                print("LOG: [Info] ----> corect answer. Strike \(gameState.getStreak())")
                gameState.CapturedAnswer = ""
                currentAnswerWindow = 0.0
                if gameState.getStreak() + 1 == igniterConfig.maxStreak {
                    gameState.incrementCombo()
                    gameState.setStreak(value: 0)
                } else {
                    gameState.incrementStreak(value: 1)
                }
                
                NextFoo()
            }
        } else {
            NextFoo()
            gameState.setStreak(value: 0)
            currentAnswerWindow = 0
        }
        
        if(gameElapsedTime > igniterConfig.levelDuration) {
            gameState.setState(state: .stop)
            timer.stop()
            wordRenderer.CurrentFoo = WordFoo(Word: "Game Over", Reward: 0)
        } */
    }
}
