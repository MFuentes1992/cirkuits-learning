//
//  TextureScene.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 14/02/26.
//  The purpose of this file is to make a PoC of loading a wavefront (.obj) and a texture (.png) and render into a scene.
//

import MetalKit

class TextureScene: SceneProtocol {
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0.0
    var baseColorTexture: MTLTexture!
    var mesh: MTKMesh!
    
    var triangleBuff: MTLBuffer!
    
    //TODO: replace
    struct Point {
        var position: SIMD3<Float>;
        var color: SIMD4<Float>;
    }
    
    var triangle: [Point] = [
        Point(position: simd_float3(-1.0, -1.0, 0.0), color: simd_float4(0.0, 1.0, 0.0, 1.0)),
        Point(position: simd_float3(1.0, -1.0, 0.0), color: simd_float4(1.0, 0.0, 0.0, 1.0)),
        Point(position: simd_float3(0.0, 1.0, 0.0), color: simd_float4(0.0, 0.0, 1.0, 1.0)),
    ]
    
    struct Uniforms {
       var modelMatrix: float4x4;
    }
    
    init(device: MTLDevice) {
        self.device = device
        let library = device.makeDefaultLibrary()!
        // let vertexFunction = library.makeFunction(name: "vertex_main")!
        // let fragmentFunction = library.makeFunction(name: "fragment_main")!
        
        //TODO: replace me
        let vertexFunction = library.makeFunction(name: "vertex_shader")!
        let fragmentFunction = library.makeFunction(name: "fragment_shader")!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.mesh = ObjLoader.loadModel(device: device)!
        // let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        // pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {  print("Pipeline creation error \(error)") }
        
        self.baseColorTexture = ObjLoader.loadTexture(device: device)
        
        //TODO: replace
        triangleBuff = device.makeBuffer(bytes: triangle, length: MemoryLayout<Point>.stride * 3, options: .storageModeShared)
    }
    
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {
        encoder.setRenderPipelineState(pipelineState)
        
        time += 0.02
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = matrix_float4x4_projection(degree:45, aspect: aspect, near: 0.1, far: 100.0)
        let viewMatrix = makeTranslationMatrix(x: 0,y: 1.0,z: 5.0)
        let modelMatrix = projectionMatrix * viewMatrix
        //let rotation = matrix_rotation(radians: time, axis: simd_float3(0, 1, 0))
        // let scaleMatrix = matrix_scale(1.0, 1.0, 1.0)
        // let modelMatrix = rotation * scaleMatrix
        // let modelMatrix = matrix_rotation(radians: time, axis: simd_float3(0, 1, 0))
        // let modelMatrix = makeModelMatrix(position: <#T##SIMD3<Float>#>, rotation: <#T##SIMD3<Float>#>, scale: <#T##SIMD3<Float>#>)
        var uniforms = Uniforms(modelMatrix: modelMatrix)
       
        encoder.setVertexBuffer(triangleBuff, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        // encoder.setFragmentTexture(baseColorTexture, index: 0)
        
        //print("total mesh vBuffers: \(mesh.vertexBuffers.count)")
        /*for(index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else { return }
            //print("index: \(index)")
            //let vertexBuffer = mesh.vertexBuffers[index]
            //encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
        }*/
        
        // let vertexBuffer = mesh.vertexBuffers[0]
        // encoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: 0)
        
        /*for submesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }*/
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        
    }
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        
    }
}
