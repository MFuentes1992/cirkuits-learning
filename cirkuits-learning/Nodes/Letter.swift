//
//  Letter.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 06/08/25.
//
import simd
import MetalKit

class Letter {
    var mesh: Mesh!
    var margin: Float = 0
    var bbLeftX: Float = 0
    var bbRightX: Float = 0
    var width: Float { return bbRightX - bbLeftX }
    var uniformBuffer: MTLBuffer!
    var transform: simd_float4x4 = matrix_identity_float4x4

    init(letter: String, device: MTLDevice) {
        if(letter == " ") { return }
        guard let url = Bundle.main.url(forResource: "\(letter.lowercased())_letter", withExtension: "obj") else {
            fatalError("No se pudo encontrar letter en el bundle. \(letter)")
        }
        
        let result = ObjLoader.loadMesh(from: url, device: device);
        mesh = result.0
        bbLeftX = result.1
        bbRightX = result.2
    }
    
    func getModel() -> Mesh {
        return mesh;
    }
}
