import MetalKit
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
    
    init(device:MTLDevice!) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        sceneManager = SceneManager(device: device)
        sceneManager.setCurrentScene(sceneName: "Igniter")
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        sceneManager.encode(encoder: commandEncoder)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
}
