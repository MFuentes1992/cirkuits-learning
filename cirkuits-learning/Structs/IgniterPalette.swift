//
//  IgniterPalette.swift
//  cirkuits-learning
//
//  Central colour palette for the Igniter scene rework.
//  Values sampled directly from the target design screenshots
//  (Igniter Compendium) so the HUD matches 1:1.
//

import UIKit

enum IgniterPalette {
    // MARK: Backgrounds
    static let navy        = UIColor(hex: 0x1D1C3C)   // base game background
    static let navyPattern = UIColor(hex: 0x27286F)   // swirl pattern lines
    static let cream       = UIColor(hex: 0xFFF4CF)   // manila background / icon fill
    static let creamPattern = UIColor(hex: 0xFCE9B8)  // subtle cream pattern lines

    // MARK: Core accents
    static let pink   = UIColor(hex: 0xFD6D7D)        // dots, score circle, buttons
    static let teal   = UIColor(hex: 0x2DDFD0)        // checkmark, "Best" pill
    static let white  = UIColor.white
    static let navyInk = UIColor(hex: 0x363851)       // dark text on light surfaces

    // MARK: Streak funnel gradient (top -> bottom, fills bottom-up)
    static let streakMagenta  = UIColor(hex: 0xCF6ED8)
    static let streakLavender = UIColor(hex: 0x9376E4)
    static let streakBlue     = UIColor(hex: 0x02B9F2)
    static let streakTeal     = UIColor(hex: 0x2DDFD0)
    static let streakLime     = UIColor(hex: 0xD1F267)

    /// Ordered top -> bottom. Index 0 is the top (widest) bar.
    static let streakBars: [UIColor] = [
        streakMagenta, streakLavender, streakBlue, streakTeal, streakLime
    ]

    // MARK: "Nice!" checkmark offset outlines
    static let checkCyan   = UIColor(hex: 0x0EDFEC)
    static let checkPurple = UIColor(hex: 0xCF6ED8)
    static let checkLime   = UIColor(hex: 0xD1F267)
    static let checkBlue   = UIColor(hex: 0x02B9F2)
    static let checkShadow = UIColor(hex: 0x19989F)   // teal drop-shadow side

    // MARK: Word brackets
    static let bracketYellow = UIColor(hex: 0xFBC629)
    static let bracketPink   = UIColor(hex: 0xFD6D7D)

    // MARK: Fire
    static let fireRed    = UIColor(hex: 0xE04136)
    static let fireOrange = UIColor(hex: 0xFF7C2B)
    static let fireAmber  = UIColor(hex: 0xFFBE3B)
    static let fireCream  = UIColor(hex: 0xFFF5D4)

    /// Cool -> hot, used to tint flame pixels by height.
    static let fireRamp: [UIColor] = [fireRed, fireOrange, fireAmber, fireCream]

    // MARK: GameOver
    static let hexPastelBlue   = UIColor(hex: 0xCEF8FB)
    static let hexPastelPink   = UIColor(hex: 0xF5E2F7)
    static let hexPastelPurple = UIColor(hex: 0xE9E3F9)
    static let retryMagenta = UIColor(hex: 0xCF6ED8)
    static let exitLime     = UIColor(hex: 0xD1F267)
}

extension UIColor {
    /// Convenience initialiser from a 0xRRGGBB integer.
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
