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
    private var slideDirection: Float = 1.0
    private var layoutBondingBox: CGRect!
    private var time: Float = 0.0
    private var shouldAnimateLayout: Bool = false
    private var acceleration: Float = 0.0
    private var animationAmout: Float = 0.0

    
    init (config: WordLayoutConfig, device: MTLDevice) {
        self.config = config
        self.device = device
    }
    
    func setWord(word: String) throws {
        self.letters.removeAll()
        for letter in word {
            let letter = Letter(letter: String(letter), device: self.device)
            self.letters.append(letter)
        }
        createLinearTransform(initialPositionX: 0.0, initialPositionY: 20)
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
        
    private func createLinearTransform(initialPositionX: Float, initialPositionY: Float = 0.0) {
        let totalWidth = calculateLinearWidth()
        var currentX: Float = initialPositionX - totalWidth/2
        
        if(totalWidth >= config.maxLinearWidth) {
            currentX = -totalWidth
            shouldAnimateLayout = true
        } else {
            shouldAnimateLayout = false
        }
        
        layoutBondingBox = CGRect(x: CGFloat(currentX), y: 0, width: CGFloat(totalWidth), height: 0.0)
        for letter in letters {
            if(letter.mesh == nil) {
                currentX += config.blankSpaceWidth
                continue
            }
            // Create transform matrix
            var transform = matrix_identity_float4x4
            transform.columns.3.x = currentX
            transform.columns.3.y = initialPositionY
            
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
        acceleration = abs(cos(time))
        animationAmout = (acceleration * slideDirection)
        for i in 0..<letters.count {
            var transform = letters[i].transform
            transform.columns.3.x += animationAmout
            letters[i].transform = transform
        }
        layoutBondingBox.origin.x += CGFloat(animationAmout)
        
        // -- 0 is the middle point in z,y,z coodinate system
        if(layoutBondingBox.origin.x > 0) {
            slideDirection = -1
        }
        
        if(layoutBondingBox.origin.x + layoutBondingBox.width < 0) {
            slideDirection = 1
        }
    }
}
