import MetalKit
import Foundation
//
//  Renderer.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 04/06/25.
//

@MainActor
class Renderer:NSObject, MTKViewDelegate {
    let device:MTLDevice
    let commandQueue:MTLCommandQueue!
    let sceneManager:SceneManager!
    private var transcription = ""
    // private var hudController:HudController!
    private var timer: TimeController
    private var gameState: GameState

    /// Standard "nearest fragment wins" depth test. Shared by every scene, so
    /// it's set once per pass in `draw(in:)` rather than per renderer.
    private let depthState: MTLDepthStencilState


    init(device:MTLDevice!, view: MTKView!) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor: depthDescriptor)!

        timer = TimeController()
        gameState = GameState(gameState: .stop, timer: timer)
       //  self.hudController = HudController(parentView: view, gameState: gameState)
        sceneManager = SceneManager(device: device, view: view, gameState: self.gameState)
        sceneManager.setCurrentScene(scene: .Menu)
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
        commandEncoder.setDepthStencilState(depthState)
        sceneManager.encode(encoder: commandEncoder, view: view)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        //TODO: We need to stop timmer on game over
        /* if gameState.CurrentState == .stop {
            timer.stop()
        } */
                
        // hudController.updateHud()
        
    }
    
}
