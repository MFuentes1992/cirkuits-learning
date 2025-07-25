//
//  SceneManager.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit


class SceneManager: SceneProtocol {
    var device: MTLDevice!
    var currentScene: SceneProtocol!
    // TODO: Create scene manager state machine
    /* var scenes: [String: SceneProtocol] = [
        "Igniter": IgniterScene(),
        "Menu": MenuScene()
    ] */
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func setCurrentScene(sceneName: String) {
        self.currentScene = IgniterScene(device: self.device);
        
    }
    
    func encode(encoder: any MTLRenderCommandEncoder) {
        self.currentScene.encode(encoder: encoder)
    }
    
}
