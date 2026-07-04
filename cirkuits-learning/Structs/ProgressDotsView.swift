//
//  ProgressDotsView.swift
//  cirkuits-learning
//
//  Top-of-screen progress row: a line of pink dots where filled dots
//  represent completed prompts. Matches the dotted header in the
//  Igniter reference screens.
//
import UIKit

class ProgressDotsView: UIView {

    private var total: Int
    private var filled: Int = 0
    private var dotLayers: [CAShapeLayer] = []

    private let dotDiameter: CGFloat = 12
    private let filledColor = IgniterPalette.pink
    private let emptyColor  = IgniterPalette.pink.withAlphaComponent(0.35)

    init(total: Int) {
        self.total = max(1, total)
        super.init(frame: .zero)
        backgroundColor = .clear
        buildDots()
    }

    required init?(coder: NSCoder) {
        self.total = 8
        super.init(coder: coder)
        backgroundColor = .clear
        buildDots()
    }

    private func buildDots() {
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
        for _ in 0..<total {
            let dot = CAShapeLayer()
            dot.fillColor = emptyColor.cgColor
            layer.addSublayer(dot)
            dotLayers.append(dot)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard total > 0 else { return }
        // Evenly distribute dot centres across the available width.
        let usable = bounds.width - dotDiameter
        let step = total > 1 ? usable / CGFloat(total - 1) : 0
        let cy = bounds.midY
        for (i, dot) in dotLayers.enumerated() {
            let cx = dotDiameter / 2 + CGFloat(i) * step
            let rect = CGRect(x: cx - dotDiameter / 2, y: cy - dotDiameter / 2,
                              width: dotDiameter, height: dotDiameter)
            dot.path = UIBezierPath(ovalIn: rect).cgPath
        }
        applyState()
    }

    private func applyState() {
        for (i, dot) in dotLayers.enumerated() {
            dot.fillColor = (i < filled ? filledColor : emptyColor).cgColor
        }
    }

    /// Update how many prompts have been completed.
    func setProgress(filled: Int) {
        self.filled = min(max(0, filled), total)
        applyState()
    }

    /// Reconfigure the number of dots (e.g. when the stage word-count changes).
    /// No-op when the count is unchanged so it is safe to call every frame.
    func setTotal(_ value: Int) {
        let clamped = max(1, value)
        guard clamped != total else { return }
        total = clamped
        buildDots()
        setNeedsLayout()
    }
}
