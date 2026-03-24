//
//  SceneManager.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit


class SceneManager: SceneProtocol {
    var device: MTLDevice!
    var view: MTKView!
    var currentScene: SceneProtocol!
    private var gameState: GameState!
   
    
    init(device: MTLDevice, view: MTKView, gameState: GameState) {
        self.gameState = gameState
        self.device = device
        self.view = view
        self.gameState = gameState
    }
    
    func setCurrentScene(scene: GameScenes) {
        let tmp: SceneProtocol
        switch scene {
        case .CountDown:
            tmp = CountDownScene(parentView: view, gameState: gameState, requestScene: {
                (scene: GameScenes) -> Void in
                self.view.subviews.forEach { $0.removeFromSuperview() }
                self.gameState.CurrentState = .running
                self.setCurrentScene(scene: scene)
            }, nextScene: .Igniter)
        case .Igniter:
            tmp = IgniterScene(device: self.device, view: self.view,
                               gameState: self.gameState, currentFooIndex: 0,
                               requestScene: { [weak self] scene in
                                   guard let self else { return }
                                   self.view.subviews.forEach { $0.removeFromSuperview() }
                                   self.setCurrentScene(scene: scene)
                               })
        case .GameOver:
            tmp = GameOverScene(parentView: view, gameState: gameState,
                                requestScene: { [weak self] scene in
                                    guard let self else { return }
                                    self.view.subviews.forEach { $0.removeFromSuperview() }
                                    self.gameState.reset()
                                    self.setCurrentScene(scene: scene)
                                })
        }
        currentScene = tmp
        let levelConfig = LevelConfig(timeToLive: 2.0, timeToAnswer: 2.0, levelDuration: 10, lives: 3, levelCountDown: 3)
        self.gameState.WordTimeToLive = levelConfig.timeToLive
        self.gameState.WordTimeToAnswer = levelConfig.timeToAnswer
        self.gameState.LevelDuration = levelConfig.levelDuration
        self.gameState.Lives = levelConfig.lives
        self.gameState.CountDown = Double(levelConfig.levelCountDown)
        self.gameState.ConfigLoaded = true
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        self.currentScene.handlePanGesture(gesture: gesture, location: location)
    }
    
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        self.currentScene.handlePinchGesture(gesture: gesture)
    }
    
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        self.currentScene.encode(encoder: encoder, view: view)
    }    
}
