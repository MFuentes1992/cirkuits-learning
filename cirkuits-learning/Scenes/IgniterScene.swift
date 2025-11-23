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
    private var currenWordIndex: Int
    private var igniterConfig: LevelConfig!
    private var gameElapsedTime: Double
    private var currentAnswerWindow: Double
    private var gameState: GameState!

    var meshPipeLine: MTLRenderPipelineState!
    var lastPanLocation: CGPoint = .zero
    
    let wordBank = ["Articulate", "Enthusiastic", "Absolutely", "Particularly", "Extraordinary", "Specifically", "Uniquely", "Passionately", "Radiantly", "Eagerly"]

    init(device: MTLDevice, view: MTKView, gameState: GameState,
         currentWodIndex: Int = 0, isGameOver: Bool = false, isPaused: Bool = false,
         score: Double = 0, strikeCount: Int = 0) {
        self.device = device
        self.gameState = gameState
        self.currenWordIndex = currentWodIndex
        self.gameElapsedTime = 0
        self.currentAnswerWindow = 0
        igniterConfig = LevelConfig(timeWindow: 5, levelDuration: 60, defaultPoints: 10)
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
        camera = Camera(settings: cameraSettings)
        wordRenderer = WordRenderer(device: device, screenWidth: Float(view.bounds.width))
        wordRenderer.setWord(wordBank[currenWordIndex])
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
    
    func changeWord() {
        currenWordIndex = (currenWordIndex + 1) % wordBank.count //
        wordRenderer.setWord(wordBank[currenWordIndex])
    }
    
    // -- Encode is called by update.
    func encode(encoder: any MTLRenderCommandEncoder) {
        timer.update()
        if(gameState.getCurrentState() == .stop) {
            return
        }
                
        if gameState.getCurrentState() == .running || gameState.getCurrentState() == .pause {
            if gameState.getCurrentState() != .pause {
                wordRenderer.update(deltaTime: 1.0/60)
                gameState.decrementTime(time: Double(timer.getTickSeconds()))
                gameElapsedTime += Double(timer.getTickSeconds())
                currentAnswerWindow += Double(timer.getTickSeconds())
                print("captured answer:\(gameState.capturedAnser)")
            }
            wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
        }
        
        if(currentAnswerWindow > igniterConfig.timeWindow) {
            changeWord()
            currentAnswerWindow = 0
        }
        
        if(gameElapsedTime > igniterConfig.levelDuration) {
            gameState.setState(state: .stop)
            timer.stop()
            wordRenderer.setWord("Game Over")
            
        }
        
        // TODO: Game should not control countDown/ start time
        
       /* if(Int.random(in: 1...100) == 1 && gameState.getCurrentState() == .running) {
            gameState.incrementScore(increment: Int(igniterConfig.defaultPoints))
            if(Int.random(in: 0...10) == 1) {
                gameState.setStrike(value: true )
            }
        } */
    }
}
