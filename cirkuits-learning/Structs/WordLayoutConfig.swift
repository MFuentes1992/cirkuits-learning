//
//  WordLayoutConfig.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 07/09/25.
//
import SwiftUI

struct WordLayoutConfig {
    let letterSpacing: Float
    let blankSpaceWidth: Float
    /// Gap between one line's glyph band and the next.
    let lineSpacing: Float

    init(letterSpacing: Float = 2.5,
         blankSpaceWidth: Float = 10,
         lineSpacing: Float = 6) {
        self.letterSpacing = letterSpacing
        self.blankSpaceWidth = blankSpaceWidth
        self.lineSpacing = lineSpacing
    }
}

struct UILayoutLookAndFeel {
    let color: UIColor
    let foreColor: UIColor
    let buttonSize: CGFloat
    let fontSize: CGFloat
    
    init(color: UIColor,
         foreColor: UIColor,
         buttonSize: CGFloat,
         fontSize: CGFloat) {
        self.color = color
        self.foreColor = foreColor
        self.buttonSize = buttonSize
        self.fontSize = fontSize
    }
}
