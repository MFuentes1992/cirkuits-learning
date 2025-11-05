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
    private var gameDuration: Float
    private var isGameOver: Bool
    private var isPaused: Bool
    private var strikeCount: Int
    private var score: Double
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
        self.gameDuration = 0
        self.isGameOver = isGameOver
        self.isPaused = isPaused
        self.score = score
        self.strikeCount = strikeCount
        igniterConfig = LevelConfig(timeWindow: 5, levelDuration: 60)
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
        timer = TimeController(startTime: igniterConfig.timeWindow, countDown: true)
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
        if(isGameOver) {
            return
        }
        wordRenderer.update(deltaTime: 1.0/60)
        
        if(!isPaused) {
            timer.update()
        }
        
        if(timer.isComplete()) {
            self.strikeCount = 0
            changeWord()
            timer.start()
            gameDuration += timer.getEllapsedTime()
        }
        
        if(gameDuration >= igniterConfig.levelDuration) {
            isGameOver =  true
            timer.stop()
            wordRenderer.setWord("Game Over")
            
        }
        
        if(Int.random(in: 1...60) % 60 == 0 && !isPaused) {
            self.score += 1
            self.strikeCount += 1
        }
        
        if self.isCombo() {
            self.strikeCount = 0
            gameState.incrementCombo()
        }
        
        wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }
    
    func getScore() -> Double {
        return self.score
    }
    
    func togglePaused() {
        self.isPaused = !self.isPaused
    }
    
    func isCombo() -> Bool {
        if self.strikeCount >= 5 {
            self.strikeCount = 0
            return true
        }
        return false
    }
    
}
