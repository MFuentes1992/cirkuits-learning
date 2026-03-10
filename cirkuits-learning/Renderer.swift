import MetalKit
import Foundation
//
//  Renderer.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/06/25.
//

class Renderer:NSObject, MTKViewDelegate {
    let device:MTLDevice
    let commandQueue:MTLCommandQueue!
    let sceneManager:SceneManager!
    private var transcription = ""
    private var hudController:HudController!
    private var timer: TimeController
    private var gameState: GameState
    
    
    init(device:MTLDevice!, view: MTKView!) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        timer = TimeController()
        gameState = GameState(gameState: .stop, timer: timer)
        self.hudController = HudController(parentView: view, gameState: gameState)
        sceneManager = SceneManager(device: device, view: view, gameState: self.gameState)
        sceneManager.setCurrentScene(sceneName: "Igniter")
        timer.start()
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func handlePanEvents(gesture: UIPanGestureRecognizer, location: CGPoint) {
        sceneManager.handlePanGesture(gesture: gesture, location: location)
    }
    
    func handlePinchEvents(gesture: UIPinchGestureRecognizer) {
        sceneManager.handlePinchGesture(gesture: gesture)
    }
    
    func draw(in view: MTKView) {
        timer.update()
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        sceneManager.encode(encoder: commandEncoder, view: view)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        if gameState.CurrentState == .stop {
            timer.stop()
        }
                
        hudController.updateHud()
        
    }
    
}
