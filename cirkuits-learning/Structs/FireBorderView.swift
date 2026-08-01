//
//  FireBorderView.swift
//  cirkuits-learning
//
//  Animated pixelated flame that rises from the bottom of the screen.
//  Its height/intensity is driven by the player's streak ("ignition"):
//  a cold streak shows only embers, a hot streak a full blaze.
//
import UIKit

class FireBorderView: UIView {

    // MARK: Grid
    private let cell: CGFloat = 14
    private var cols = 0
    private var rows = 20
    private var cells: [[CALayer]] = []          // [col][row], row 0 = bottom

    // MARK: Animation
    private var displayLink: CADisplayLink?
    private var t: CFTimeInterval = 0
    private var phases: [CGFloat] = []           // per-column noise offset

    /// 0 = no fire, 1 = maximum blaze. Smoothly interpolated toward `targetIntensity`.
    private var intensity: CGFloat = 0
    private var targetIntensity: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    // MARK: Grid build
    override func layoutSubviews() {
        super.layoutSubviews()
        let newCols = max(1, Int(ceil(bounds.width / cell)))
        let newRows = max(1, Int(ceil(bounds.height / cell)))
        if newCols != cols || newRows != rows || cells.isEmpty {
            cols = newCols
            rows = newRows
            rebuildGrid()
        }
    }

    private func rebuildGrid() {
        cells.forEach { $0.forEach { $0.removeFromSuperlayer() } }
        cells.removeAll()
        phases.removeAll()

        for c in 0..<cols {
            phases.append(CGFloat(c) * 0.6 + CGFloat.random(in: 0...6))
            var column: [CALayer] = []
            for r in 0..<rows {
                let l = CALayer()
                // row 0 = bottom of the view
                l.frame = CGRect(x: CGFloat(c) * cell,
                                 y: bounds.height - CGFloat(r + 1) * cell,
                                 width: cell, height: cell)
                l.isHidden = true
                layer.addSublayer(l)
                column.append(l)
            }
            cells.append(column)
        }
    }

    // MARK: Public control
    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    // Stop animating (and break the CADisplayLink retain cycle) when the
    // scene removes this view from the hierarchy.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { stop() }
    }

    deinit {
        displayLink?.invalidate()
    }

    /// Map a streak value to flame intensity. `streak` of `maxStreak`+ = full blaze.
    func setStreak(_ streak: Int, maxStreak: Int) {
        let denom = max(1, maxStreak)
        targetIntensity = min(1.0, CGFloat(streak) / CGFloat(denom))
    }

    /// Directly set 0...1 intensity.
    func setIntensity(_ value: CGFloat) {
        targetIntensity = min(1, max(0, value))
    }

    // MARK: Frame update
    @objc private func tick(_ link: CADisplayLink) {
        t += link.duration
        // Ease current intensity toward the target for smooth ignite/cooldown.
        intensity += (targetIntensity - intensity) * 0.08

        guard cols > 0, rows > 0 else { return }

        // A permanent ember baseline so a faint fire always licks the edge.
        let baseline: CGFloat = 0.12 + 0.6 * intensity   // fraction of rows
        let variance: CGFloat = 0.10 + 0.35 * intensity

        for c in 0..<cols {
            let p = phases[c]
            // Layered sine "noise" for an organic flicker.
            let n = sin(CGFloat(t) * 3.0 + p)
                  + 0.5 * sin(CGFloat(t) * 6.3 + p * 1.7)
                  + 0.25 * sin(CGFloat(t) * 11.0 + p * 2.3)
            let norm = (n / 1.75) * 0.5 + 0.5                // 0...1
            let heightFrac = baseline + variance * (norm - 0.5) * 2
            let litRows = Int((heightFrac * CGFloat(rows)).rounded())

            for r in 0..<rows {
                let lit = r < litRows
                let l = cells[c][r]
                l.isHidden = !lit
                if lit {
                    l.backgroundColor = fireColor(row: r, litRows: litRows).cgColor
                }
            }
        }
    }

    /// Hot at the base (cream/amber), cooling to red at the tips.
    private func fireColor(row: Int, litRows: Int) -> UIColor {
        guard litRows > 1 else { return IgniterPalette.fireCream }
        let f = CGFloat(row) / CGFloat(litRows - 1)   // 0 base -> 1 tip
        switch f {
        case ..<0.25: return IgniterPalette.fireCream
        case ..<0.55: return IgniterPalette.fireAmber
        case ..<0.82: return IgniterPalette.fireOrange
        default:      return IgniterPalette.fireRed
        }
    }
}
