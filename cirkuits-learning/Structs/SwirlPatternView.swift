//
//  SwirlPatternView.swift
//  cirkuits-learning
//
//  Recolourable tiled "swirl + ring" background used behind the 3D
//  letters. Rendered in code so the same motif can be tinted navy
//  (gameplay) or cream (menu / calm states).
//
import UIKit

class SwirlPatternView: UIView {

    enum Style {
        case navy
        case cream

        var base: UIColor {
            switch self {
            case .navy:  return IgniterPalette.navy
            case .cream: return IgniterPalette.cream
            }
        }
        var line: UIColor {
            switch self {
            case .navy:  return IgniterPalette.navyPattern
            case .cream: return IgniterPalette.creamPattern
            }
        }
    }

    private var style: Style = .navy
    private let tile: CGFloat = 64

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = style.base
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = style.base
    }

    func setStyle(_ style: Style) {
        self.style = style
        backgroundColor = style.base
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Base fill
        ctx.setFillColor(style.base.cgColor)
        ctx.fill(rect)

        // Motif stroke
        ctx.setStrokeColor(style.line.cgColor)
        ctx.setLineWidth(3)
        ctx.setLineCap(.round)

        let cols = Int(ceil(rect.width / tile)) + 1
        let rows = Int(ceil(rect.height / tile)) + 1
        let r = tile * 0.28

        for row in 0..<rows {
            for col in 0..<cols {
                let ox = CGFloat(col) * tile
                let oy = CGFloat(row) * tile
                // Alternate rings and S-swirls in a checkerboard for a busy,
                // interlocking look reminiscent of the reference pattern.
                if (row + col) % 2 == 0 {
                    ctx.addEllipse(in: CGRect(x: ox + tile/2 - r, y: oy + tile/2 - r,
                                              width: r * 2, height: r * 2))
                    ctx.strokePath()
                } else {
                    drawSwirl(ctx, cx: ox + tile/2, cy: oy + tile/2, radius: r,
                              flip: (row % 2 == 0))
                }
            }
        }
    }

    private func drawSwirl(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat, flip: Bool) {
        // Two opposing half-arcs forming an "S".
        let s: CGFloat = flip ? -1 : 1
        ctx.addArc(center: CGPoint(x: cx - radius/2 * s, y: cy - radius/2),
                   radius: radius/2, startAngle: .pi/2, endAngle: -.pi/2, clockwise: flip)
        ctx.strokePath()
        ctx.addArc(center: CGPoint(x: cx + radius/2 * s, y: cy + radius/2),
                   radius: radius/2, startAngle: -.pi/2, endAngle: .pi/2, clockwise: flip)
        ctx.strokePath()
    }
}
