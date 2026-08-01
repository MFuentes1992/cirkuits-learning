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
    private var letters = [Character: Letter]()
    private var lettersOnStage: [Letter] = []
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
        self.lettersOnStage.removeAll()
        for letter in word {
            let key = letter.isLetter ? Character(letter.lowercased()) : Character("_")
            let template: Letter
            if let cached = letters[key] {
                template = cached
            } else {
                template = Letter(letter: key, device: self.device)
                letters[key] = template
            }
            // Each on-stage occurrence needs its own transform, but shares
            // the cached mesh — so repeated letters don't overlap.
            lettersOnStage.append(Letter(copying: template))
        }
        createLinearTransform(initialPositionX: 0.0, initialPositionY: 20)
    }
    
    func getLetters() -> [Letter] {
        return lettersOnStage
    }

    /// World-space centre of the letters currently on stage — the layout
    /// translation applied to each glyph's own bounding box. Empty stage
    /// returns the origin.
    var wordCenter: SIMD3<Float> {
        let placed = lettersOnStage.filter { $0.mesh != nil }
        guard !placed.isEmpty else { return .zero }

        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        for letter in placed {
            let offsetX = letter.transform.columns.3.x
            let offsetY = letter.transform.columns.3.y
            minX = min(minX, letter.bbLeftX + offsetX)
            maxX = max(maxX, letter.bbRightX + offsetX)
            minY = min(minY, letter.bbBottomY + offsetY)
            maxY = max(maxY, letter.bbTopY + offsetY)
        }
        return SIMD3<Float>((minX + maxX) / 2, (minY + maxY) / 2, 0)
    }
    
    func getLetterTransforms() -> [simd_float4x4] {
        return lettersOnStage.map { $0.transform }
    }
    
    func update(deltaTime: Float) {
        updateLinearTransforms(deltaTime: deltaTime)
    }
        
    private func calculateLinearWidth() -> Float {
        guard !lettersOnStage.isEmpty else { return 0 }
        
        let totalLetterWidth = lettersOnStage.reduce(0) { $0 + $1.width }
        let totalSpacing = Float(lettersOnStage.count - 1) * config.letterSpacing
        return totalLetterWidth + totalSpacing
    }
        
    private func createLinearTransform(initialPositionX: Float, initialPositionY: Float = 0.0) {
        let totalWidth = calculateLinearWidth()
        var currentX: Float = initialPositionX - totalWidth / 2
        
        if totalWidth >= config.maxLinearWidth {
            currentX = -totalWidth
            shouldAnimateLayout = true
        } else {
            shouldAnimateLayout = false
        }
        
        layoutBondingBox = CGRect(x: CGFloat(currentX), y: 0, width: CGFloat(totalWidth), height: 0.0)
        for letter in lettersOnStage {
            if letter.mesh == nil {
                currentX += config.blankSpaceWidth
                continue
            }
            var transform = matrix_identity_float4x4
            // Offset by -bbLeftX so the letter's visual left edge aligns with currentX
            transform.columns.3.x = currentX - letter.bbLeftX
            transform.columns.3.y = initialPositionY
            
            letter.transform = transform
            currentX += letter.width + config.letterSpacing
        }
    }
   
    func cleanStageLetters() {
        lettersOnStage.removeAll()
        letters.removeAll()
    }
    
    private func updateLinearTransforms(deltaTime: Float) {
        if(!shouldAnimateLayout) {
            return
        }
        time += deltaTime * config.speed
        acceleration = abs(cos(time))
        animationAmout = (acceleration * slideDirection)
        for i in 0..<lettersOnStage.count {
            var transform = lettersOnStage[i].transform
            transform.columns.3.x += animationAmout
            lettersOnStage[i].transform = transform
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
