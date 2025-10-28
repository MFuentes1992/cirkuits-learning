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
    private var rotationAngle: Float = 0.0
    private var rotationDirection: Float = -1.0
    private var startingAngle: Float = 0.0
    
    init (config: WordLayoutConfig, device: MTLDevice) {
        self.config = config
        self.device = device
    }
    
    func setWord(word: String) throws {
        for letter in word {
            let letter = Letter(letter: String(letter), device: self.device)
            self.letters.append(letter)
        }
        
        calculateOptimalLayout()
        updateLetterTransforms()
    }
    
    func getLetters() -> [Letter] {
        return letters
    }
    
    func getLetterTransforms() -> [simd_float4x4] {
        return letters.map { $0.transform }
    }
    
    func update(deltaTime: Float) {
        if case .circular = currentLayoutMode {
            rotationAngle += config.rotationSpeed * deltaTime * rotationDirection
            updateLetterTransforms()
        }
    }
    
    private func updateLetterTransforms() {
         switch currentLayoutMode {
         case .linear:
             updateLinearTransforms()
         case .circular(let radius, let totalAngle):
             updateCircularTransforms(radius: radius, totalAngle: totalAngle)
         }
     }
    
    private func calculateOptimalLayout() {
        let totalLinearWidth = calculateLinearWidth()
        
        if totalLinearWidth <= config.maxLinearWidth {
            currentLayoutMode = .linear
        } else {
            let circleInfo = calculateCircularLayout()
            currentLayoutMode = .circular(radius: circleInfo.radius, totalAngle: circleInfo.totalAngle)
        }
    }
    
    private func calculateLinearWidth() -> Float {
        guard !letters.isEmpty else { return 0 }
        
        let totalLetterWidth = letters.reduce(0) { $0 + $1.width }
        let totalSpacing = Float(letters.count - 1) * config.letterSpacing
        return totalLetterWidth + totalSpacing
    }
    
    private func calculateCircularLayout() -> (radius: Float, totalAngle: Float) {
        guard !letters.isEmpty else { return (0, 0) }
        
        // Calculate individual letter arc lengths
        let letterArcLengths = letters.map { letter in
            letter.width + config.letterSpacing
        }
        
        let totalArcLength = letterArcLengths.reduce(0, +)
        
        // Calculate radius based on total arc length
        // We want the arc to subtend a reasonable angle  (like 120-180 degrees max)
        let maxAngle: Float = .pi * 0.4 // 135 degrees
        let minRadius = totalArcLength / maxAngle
        
        // Apply multiplier for better visual spacing
        let radius = minRadius * config.circleRadiusMultiplier
        
        // Calculate actual total angle based on final radius
        let totalAngle = totalArcLength / radius
        
        return (radius, totalAngle)
    }
    
    private func updateLinearTransforms() {
        let totalWidth = calculateLinearWidth()
        var currentX: Float = -totalWidth * 0.5
        print("letters size: \(letters.count)")
        for letter in letters {
            if(letter.mesh == nil) {
                currentX += config.blankSpaceWidth
                continue
            }
            // Create transform matrix
            var transform = matrix_identity_float4x4
            transform.columns.3.x = currentX
            
            letter.transform = transform
            currentX += letter.width + config.letterSpacing            
            
            print("letter width: \(letter.width), letter bbx: \(letter.bbRightX) centre: \(currentX)")
        }
    }
    
    private func updateCircularTransforms(radius: Float, totalAngle: Float) {
        // Calculate individual letter positions on the circle
        let letterArcLengths = letters.map { $0.width + config.letterSpacing }
        // let totalArcLength = letterArcLengths.reduce(0, +)
        // var currentAngle: Float = -totalAngle * 0.5 // Start from left side
        var currentAngle: Float = 0
        
        
        for i in 0..<letters.count {
            let letter = letters[i]
            let letterArcLength = letterArcLengths[i]
            
            // Position at the center of this letter's arc
            let letterCenterAngle = currentAngle + (letterArcLength / radius) * 0.5
            let finalAngle = letterCenterAngle + rotationAngle
            startingAngle += rotationAngle
            
            if(i == 0 && finalAngle > config.circumferenceRadBounds) {
             rotationDirection = -1
             }
             
             if(i == letters.count - 1 && finalAngle < -(config.circumferenceRadBounds) && rotationDirection < 0) {
                 rotationDirection = 1
                 print("StartingAngle: \(startingAngle) finalAngle: \(finalAngle) rotationDirection: \(rotationDirection) config.circumferenceRadBounds: \(config.circumferenceRadBounds)")
             }
            
            // Calculate position on circle
            let x = radius * sin(finalAngle)
            let z = radius * cos(finalAngle) - radius // Offset so circle center is at origin
            
            // Create rotation matrix to face the center
            let rotationY = -finalAngle
            
            // Combine translation and rotation
            var transform = matrix_identity_float4x4
            
            // Apply rotation around Y-axis
            let cosY = cos(rotationY)
            let sinY = sin(rotationY)
            transform.columns.0.x = cosY
            transform.columns.0.z = sinY
            transform.columns.2.x = -sinY
            transform.columns.2.z = cosY
            
            // Apply translation
            transform.columns.3.x = x
            transform.columns.3.z = z
            
            letters[i].transform = transform
            currentAngle += letterArcLength / radius
            
            
            /* if(startingAngle < config.circumferenceRadBounds - (totalAngle * 0.5)) {
                rotationDirection = 1
            }
            
            if(startingAngle > config.circumferenceRadBounds + (totalAngle * 0.5)) {
                rotationDirection = -1
            } */
        }
        // print("starting Angle \(startingAngle)")
    }
}
