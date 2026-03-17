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
    private var currentFooIndex: Int
    private var timeToAnswer: Double
    private var wordTimeToLive: Double
    private var gameElapsedTime: Double
    private var currentAnswerWindow: Double
    private var gameState: GameState!
    private var WordFoos = [WordFoo]()
    
    // -- Local Game Track
    private var score: Int = 0
    private var combo: Int = 0

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
    
    let wordBank = ["Articulate", "Enthusiastic", "Absolutely", "Particularly", "Extraordinary", "Specifically", "Uniquely", "Passionately", "Radiantly", "Eagerly", "Wednesday", "Comfortable", "Vegetable", "Clothes", "Jewelry", "Schedule", "Chocolate", "Library", "Temperature", "Specific", "Thorough", "Though", "Through", "Thought", "Enough", "Cough", "Bough", "Chaos", "Choir", "Island"]

    init(device: MTLDevice, view: MTKView, gameState: GameState,
         currentFooIndex: Int = 0, isGameOver: Bool = false, isPaused: Bool = false,
         score: Double = 0, strikeCount: Int = 0) {
        self.device = device
        self.gameState = gameState
        self.currentFooIndex = currentFooIndex
        self.timeToAnswer = 0
        self.wordTimeToLive = 0
        self.currentAnswerWindow = 0
        self.gameElapsedTime = 0
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
    
    func nextFoo(reward: Int) {
        score += reward
        currentFooIndex = (currentFooIndex + 1) % WordFoos.count //
        wordRenderer.CurrentFoo = WordFoos[currentFooIndex]
    }
    
    func resetTimers() {
        timeToAnswer = 0
        wordTimeToLive = 0
        gameState.IsAnswering = false
    }
    
    // -- Encode is called by update.
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        if gameState.CurrentState == .running {
            gameElapsedTime += Double(gameState.Timer.getTickSeconds())
            if !gameState.IsAnswering {
                wordTimeToLive += Double(gameState.Timer.getTickSeconds())
                print("Elapsed time while NOT answering: \(wordTimeToLive) -- \(WordFoos[currentFooIndex])")
                if wordTimeToLive > gameState.WordTimeToLive {
                    nextFoo(reward: 0)
                    resetTimers()
                }
            } else if gameState.CorrectAnswer {
                nextFoo(reward: WordFoos[currentFooIndex].Reward)
                gameState.IsAnswering = false
                gameState.CorrectAnswer = false
                resetTimers()
                print("correct Answer, moving onto next...")
            } else {
                timeToAnswer += Double(gameState.Timer.getTickSeconds())
                if timeToAnswer >= gameState.WordTimeToAnswer {
                    gameState.IsAnswering = false
                    nextFoo(reward: 0)
                    resetTimers()
                    return
                }
                gameState.CorrectAnswer = WordFoos[currentFooIndex].Word.compare(gameState.CapturedAnswer, options: .caseInsensitive) == .orderedSame
                print("Player is taking time to answer.... \(gameState.CapturedAnswer)")
            }
            if gameElapsedTime >= gameState.LevelDuration {
                gameState.CurrentState = .stop
                wordRenderer.CurrentFoo = WordFoo(Word: "Game Over", Reward: 0)
            }
        }
        gameState.Score = score
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
}
