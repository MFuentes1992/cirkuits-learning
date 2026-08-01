//
//  AppFont.swift
//  cirkuits-learning
//
//  Central access to the game's brand typeface (Jaro). Jaro is a single-weight
//  display face — the `opsz` optical-size axis is baked into the static 60pt
//  cut we ship — so callers pass only a size. The system font is used as a
//  fallback if the custom font ever fails to load.
//
import UIKit
import SwiftUI

enum AppFont {
    /// PostScript name of the bundled Jaro static (see Info.plist `UIAppFonts`).
    static let jaro = "Jaro60pt-Regular"

    /// UIKit Jaro at `size`, falling back to a heavy system font.
    static func uiFont(size: CGFloat) -> UIFont {
        UIFont(name: jaro, size: size) ?? .systemFont(ofSize: size, weight: .heavy)
    }
}

extension Font {
    /// SwiftUI Jaro at `size`.
    static func jaro(_ size: CGFloat) -> Font {
        .custom(AppFont.jaro, size: size)
    }
}
