//
//  WordLayoutManager.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//
import MetalKit
import simd

enum LayoutMode {
    /// Breaks at spaces so each line fits `maxWidth`, stacks the lines centred
    /// on the origin, then scales the whole block down if a single word or the
    /// stack still overflows `maxWidth` × `maxHeight` (world units).
    case wrapped(maxWidth: Float, maxHeight: Float)
}

class WordLayoutManager {
    private var letters = [Character: Letter]()
    private var lettersOnStage: [Letter] = []
    private var config: WordLayoutConfig
    private var device: MTLDevice!
    /// Applied on the next `setWord`.
    var layoutMode: LayoutMode = .wrapped(maxWidth: .infinity, maxHeight: .infinity)
    
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
        switch layoutMode {
        case .wrapped(let maxWidth, let maxHeight):
            createWrappedTransform(maxWidth: maxWidth, maxHeight: maxHeight)
        }
    }
    
    func getLetters() -> [Letter] {
        return lettersOnStage
    }

    /// World-space bounds of the letters currently on stage — each glyph's own
    /// bounding box carried through its layout transform (translation and
    /// scale). Nil when nothing is on stage.
    var wordBounds: (min: SIMD2<Float>, max: SIMD2<Float>)? {
        let placed = lettersOnStage.filter { $0.mesh != nil }
        guard !placed.isEmpty else { return nil }

        var low = SIMD2<Float>(repeating: .greatestFiniteMagnitude)
        var high = SIMD2<Float>(repeating: -.greatestFiniteMagnitude)
        for letter in placed {
            let a = letter.transform * SIMD4<Float>(letter.bbLeftX, letter.bbBottomY, 0, 1)
            let b = letter.transform * SIMD4<Float>(letter.bbRightX, letter.bbTopY, 0, 1)
            low = simd_min(low, simd_min(SIMD2(a.x, a.y), SIMD2(b.x, b.y)))
            high = simd_max(high, simd_max(SIMD2(a.x, a.y), SIMD2(b.x, b.y)))
        }
        return (low, high)
    }

    /// World-space centre of the letters on stage; the origin when empty.
    var wordCenter: SIMD3<Float> {
        guard let bounds = wordBounds else { return .zero }
        let centre = (bounds.min + bounds.max) / 2
        return SIMD3<Float>(centre.x, centre.y, 0)
    }

    func getLetterTransforms() -> [simd_float4x4] {
        return lettersOnStage.map { $0.transform }
    }
    
    /// Greedy word wrap. Words are runs of glyphs separated by blanks; a word
    /// moves to the next line when it would overflow `maxWidth`, and a word
    /// wider than `maxWidth` on its own gets a line to itself. Lines are centred
    /// horizontally, the stack is centred vertically on the origin, and one
    /// uniform scale shrinks the block if it still doesn't fit.
    private func createWrappedTransform(maxWidth: Float, maxHeight: Float) {
        // Indices into lettersOnStage, grouped into words.
        var words: [[Int]] = [[]]
        for (index, letter) in lettersOnStage.enumerated() {
            if letter.mesh == nil {
                if !words[words.count - 1].isEmpty { words.append([]) }
            } else {
                words[words.count - 1].append(index)
            }
        }
        words.removeAll { $0.isEmpty }
        guard !words.isEmpty else { return }

        func width(of word: [Int]) -> Float {
            let glyphs = word.reduce(0) { $0 + lettersOnStage[$1].width }
            return glyphs + Float(word.count - 1) * config.letterSpacing
        }
        let wordGap = config.blankSpaceWidth + config.letterSpacing

        var lines: [(words: [[Int]], width: Float)] = []
        for word in words {
            let wordWidth = width(of: word)
            if let last = lines.last, last.width + wordGap + wordWidth <= maxWidth {
                lines[lines.count - 1].words.append(word)
                lines[lines.count - 1].width += wordGap + wordWidth
            } else {
                lines.append((words: [word], width: wordWidth))
            }
        }

        // One shared glyph band for every line, so baselines stay evenly spaced
        // regardless of which letters a line happens to contain.
        let placed = words.flatMap { $0 }.map { lettersOnStage[$0] }
        let bandTop = placed.map(\.bbTopY).max()!
        let bandBottom = placed.map(\.bbBottomY).min()!
        let lineAdvance = (bandTop - bandBottom) + config.lineSpacing

        let blockWidth = lines.map(\.width).max()!
        let blockHeight = Float(lines.count) * lineAdvance - config.lineSpacing
        let scale = min(1, maxWidth / blockWidth, maxHeight / blockHeight)

        for (lineIndex, line) in lines.enumerated() {
            let lineTop = blockHeight / 2 - Float(lineIndex) * lineAdvance
            var currentX = -line.width / 2
            for word in line.words {
                for index in word {
                    let letter = lettersOnStage[index]
                    var transform = matrix_identity_float4x4
                    transform.columns.0.x = scale
                    transform.columns.1.y = scale
                    transform.columns.2.z = scale
                    transform.columns.3.x = (currentX - letter.bbLeftX) * scale
                    transform.columns.3.y = (lineTop - bandTop) * scale
                    letter.transform = transform
                    currentX += letter.width + config.letterSpacing
                }
                currentX += config.blankSpaceWidth
            }
        }
    }

    /// Clears the stage but keeps the parsed glyph cache — re-parsing the OBJ
    /// files is the expensive part of showing a word.
    func cleanStageLetters() {
        lettersOnStage.removeAll()
    }
}
