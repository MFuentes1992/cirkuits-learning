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
    // TODO: Create scene manager state machine
    /* var scenes: [String: SceneProtocol] = [
        "Igniter": IgniterScene(),
        "Menu": MenuScene()
    ] */
    
    init(device: MTLDevice, view: MTKView, gameState: GameState) {
        self.device = device
        self.view = view
        self.gameState = gameState
    }
    
    func setCurrentScene(sceneName: String) {
       self.currentScene = IgniterScene(device: self.device, view: self.view,
                                         gameState: self.gameState, currentFooIndex: 0);
       //self.currentScene = TextureScene(device: self.device)
        
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
