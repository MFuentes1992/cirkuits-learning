//
//  WordLayoutManager.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//
import MetalKit
import simd

enum LayoutMode {
    case linear
    case circular(radius: Float, totalAngle: Float)
}

class WordLayoutManager {
    private var letters: [Letter] = []
    private var config: WordLayoutConfig
    private var device: MTLDevice!
    private var currentLayoutMode: LayoutMode = .linear
    private var slideDirection: Float = -1.0
    private var layoutBondingBox: CGRect!
    private var time: Float = 0.0
    private var shouldAnimateLayout: Bool = false
    
    init (config: WordLayoutConfig, device: MTLDevice) {
        self.config = config
        self.device = device
    }
    
    func setWord(word: String) throws {
        for letter in word {
            let letter = Letter(letter: String(letter), device: self.device)
            self.letters.append(letter)
        }
        createLinearTransform(initialPositionX: 0.0)
    }
    
    func getLetters() -> [Letter] {
        return letters
    }
    
    func getLetterTransforms() -> [simd_float4x4] {
        return letters.map { $0.transform }
    }
    
    func update(deltaTime: Float) {
        updateLinearTransforms(deltaTime: deltaTime)
    }
        
    private func calculateLinearWidth() -> Float {
        guard !letters.isEmpty else { return 0 }
        
        let totalLetterWidth = letters.reduce(0) { $0 + $1.width }
        let totalSpacing = Float(letters.count - 1) * config.letterSpacing
        return totalLetterWidth + totalSpacing
    }
        
    private func createLinearTransform(initialPositionX: Float) {
        let totalWidth = calculateLinearWidth()
        var currentX: Float = initialPositionX - totalWidth/2
        
        if(totalWidth >= config.maxLinearWidth) {
            currentX = -totalWidth
            shouldAnimateLayout = true
        }
        
        layoutBondingBox = CGRect(x: CGFloat(initialPositionX), y: 0, width: CGFloat(totalWidth), height: 0.0)
        for letter in letters {
            if(letter.mesh == nil) {
                currentX += config.blankSpaceWidth
                continue
            }
            // Create transform matrix
            var transform = matrix_identity_float4x4
            transform.columns.3.x = currentX
            
            letter.transform = transform
            currentX += config.letterWidth + config.letterSpacing
            print("Letter --> width: \(letter.width) bbR: \(letter.bbRightX) bbL: \(letter.bbLeftX)")
        }
    }
    
    private func updateLinearTransforms(deltaTime: Float) {
        if(!shouldAnimateLayout) {
            return
        }
        time += deltaTime * config.speed
        for i in 0..<letters.count {
            var transform = letters[i].transform
            transform.columns.3.x += cos(time)
            letters[i].transform = transform
        }
    }
}
