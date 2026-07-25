//
//  ScreenAsset.swift
//  cirkuits-learning
//
//  Central access to the artwork in `screen-assets/`. That art ships as loose
//  PNGs rather than an asset catalog, so `UIImage(named:)` can miss it — every
//  lookup falls back to a direct bundle path.
//
import UIKit
import SwiftUI

enum ScreenAsset {
    /// Official backdrop shared by the countdown and the game, so the two
    /// scenes hand off without a visible change.
    static let igniterBackground = "Igniter_bg_black"

    static func uiImage(_ name: String) -> UIImage? {
        UIImage(named: name)
            ?? Bundle.main.path(forResource: name, ofType: "png")
                .flatMap(UIImage.init(contentsOfFile:))
    }

    /// A full-bleed backdrop that fills `frame` and follows it as the container
    /// resizes. The caller decides where in the view hierarchy it belongs.
    static func backgroundView(_ name: String, frame: CGRect) -> UIImageView {
        let view = UIImageView(image: uiImage(name))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.frame = frame
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
}

extension Image {
    /// SwiftUI screen asset, showing a warning glyph if the art is missing.
    init(screenAsset name: String) {
        if let image = ScreenAsset.uiImage(name) {
            self.init(uiImage: image)
        } else {
            self.init(systemName: "exclamationmark.triangle")
        }
    }
}
