//
//  ComboGauge.swift
//  cirkuits-learning
//
//  Streak funnel meter for the Igniter HUD.
//  Redrawn to match the target design: a pink-outlined funnel of
//  trapezoid bars (fills bottom-up, magenta at the top / lime at the
//  bottom), a red score circle and a white "xNN" multiplier badge.
//
import UIKit

class ComboGauge: UIView {

    // MARK: Config
    private var barCount: Int = 0

    // MARK: Layout constants (points, in local space)
    private let leftX: CGFloat = 22
    private let topY: CGFloat = 6
    private let topWidth: CGFloat = 112
    private let bottomWidth: CGFloat = 66
    private let barHeight: CGFloat = 20
    private let barGap: CGFloat = 7
    private let skew: CGFloat = 10           // right-edge slant of each bar

    private var combo: Int = 0 { didSet { updateGauge() } }
    private var score: Int = 0 { didSet { scoreLabel.text = "\(score)" } }

    // MARK: Layers / subviews
    private var barLayers: [CAShapeLayer] = []
    private var barOutlineLayers: [CAShapeLayer] = []
    private let bracketLayer = CAShapeLayer()

    private let scoreCircle = UIView()
    private let scoreLabel = UILabel()
    private let badgeCircle = UIView()
    private let badgeLabel = UILabel()
    private let streakLabel = UILabel()

    // MARK: Init
    init(frame: CGRect, totalBars: Int = 5) {
        self.barCount = totalBars // Design always shows 5 elements
        super.init(frame: frame)
        setupGauge()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGauge()
    }

    private func setupGauge() {
        backgroundColor = .clear

        // Pink funnel bracket (behind the bars)
        bracketLayer.fillColor = UIColor.clear.cgColor
        bracketLayer.strokeColor = IgniterPalette.pink.cgColor
        bracketLayer.lineWidth = 3
        bracketLayer.lineJoin = .round
        bracketLayer.lineCap = .round
        layer.addSublayer(bracketLayer)

        // Funnel bars (fill + outline)
        for _ in 0..<barCount {
            let bar = CAShapeLayer()
            bar.fillColor = UIColor.clear.cgColor
            layer.addSublayer(bar)
            barLayers.append(bar)

            let outline = CAShapeLayer()
            outline.strokeColor = IgniterPalette.pink.cgColor
            outline.lineWidth = 2
            outline.lineJoin = .round
            outline.fillColor = UIColor.clear.cgColor
            layer.addSublayer(outline)
            barOutlineLayers.append(outline)
        }

        // Red score circle
        scoreCircle.backgroundColor = IgniterPalette.pink
        addSubview(scoreCircle)

        scoreLabel.font = AppFont.uiFont(size: 34)
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .center
        scoreLabel.text = "0"
        scoreCircle.addSubview(scoreLabel)

        // White multiplier badge
        badgeCircle.backgroundColor = .white
        addSubview(badgeCircle)

        badgeLabel.font = AppFont.uiFont(size: 20)
        badgeLabel.textColor = IgniterPalette.navyInk
        badgeLabel.textAlignment = .center
        badgeLabel.text = "x00"
        badgeCircle.addSubview(badgeLabel)

        // STREAK label
        streakLabel.text = "STREAK"
        streakLabel.font = AppFont.uiFont(size: 22)
        streakLabel.textColor = .white
        streakLabel.textAlignment = .left
        addSubview(streakLabel)

        updateGauge()
    }

    // MARK: Geometry
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarPaths()
        updateBracketPath()
        layoutOverlays()
    }

    /// Width of bar `i` (0 = top / widest).
    private func barWidth(_ i: Int) -> CGFloat {
        let t = CGFloat(i) / CGFloat(barCount - 1)
        return topWidth - (topWidth - bottomWidth) * t
    }

    private func barY(_ i: Int) -> CGFloat {
        topY + CGFloat(i) * (barHeight + barGap)
    }

    private var funnelBottomY: CGFloat {
        barY(barCount - 1) + barHeight
    }

    private func trapezoidPath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPath {
        // Parallelogram-style bar with a right-leaning slant, matching the
        // arrow-like edges in the reference art.
        let p = UIBezierPath()
        p.move(to: CGPoint(x: x, y: y))
        p.addLine(to: CGPoint(x: x + width, y: y))
        p.addLine(to: CGPoint(x: x + width - skew, y: y + height))
        p.addLine(to: CGPoint(x: x, y: y + height))
        p.close()
        return p.cgPath
    }

    private func updateBarPaths() {
        for i in 0..<barCount {
            let path = trapezoidPath(x: leftX, y: barY(i), width: barWidth(i), height: barHeight)
            barLayers[i].path = path
            barOutlineLayers[i].path = path
        }
    }

    private func updateBracketPath() {
        // L / U-shaped chute hugging the left side and bottom of the funnel.
        let x = leftX - 8
        let top = topY - 2
        let bottom = funnelBottomY + 40         // extends past STREAK label
        let right = leftX + topWidth * 0.55
        let r: CGFloat = 10

        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: x, y: bottom - r))
        path.addQuadCurve(to: CGPoint(x: x + r, y: bottom),
                          controlPoint: CGPoint(x: x, y: bottom))
        path.addLine(to: CGPoint(x: right - r, y: bottom))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom - r),
                          controlPoint: CGPoint(x: right, y: bottom))
        bracketLayer.path = path.cgPath
    }

    private func layoutOverlays() {
        // Multiplier badge, lower-left of the score circle.
        let badgeD: CGFloat = 54
        let badgeCX = leftX + bottomWidth * 1.1
        let badgeCY = funnelBottomY - barHeight * 0.4
        badgeCircle.frame = CGRect(x: badgeCX, y: badgeCY - badgeD / 2, width: badgeD, height: badgeD)
        badgeCircle.layer.cornerRadius = badgeD / 2
        badgeCircle.layer.shadowColor = UIColor.black.cgColor
        badgeCircle.layer.shadowOffset = CGSize(width: 1, height: 2)
        badgeCircle.layer.shadowRadius = 3
        badgeCircle.layer.shadowOpacity = 0.25
        badgeLabel.frame = badgeCircle.bounds

        // Score circle overlaps the right of the funnel, vertically centred.
        let scoreD: CGFloat = 78
        let scoreCX = leftX + topWidth * 0.8
        let scoreCY = badgeCY
        scoreCircle.frame = CGRect(x: scoreCX, y: scoreCY - (scoreD / 1.5) - ( badgeD / 2), width: scoreD, height: scoreD)
        scoreCircle.layer.cornerRadius = scoreD / 2
        scoreLabel.frame = scoreCircle.bounds
        
        // STREAK under the funnel.
        streakLabel.frame = CGRect(x: leftX - 4, y: funnelBottomY + 8, width: 140, height: 28)
    }

    // MARK: State
    private func updateGauge() {
        for i in 0..<barCount {
            // Bars fill bottom-up: bottom bar (index barCount-1) fills first.
            let depthFromBottom = barCount - i          // 1...barCount
            let isFilled = combo >= depthFromBottom
            if isFilled {
                barLayers[i].fillColor = IgniterPalette.streakBars[i].cgColor
                if combo == depthFromBottom { pulse(barLayers[i]) }
            } else {
                barLayers[i].fillColor = UIColor.clear.cgColor
            }
        }
        badgeLabel.text = String(format: "x%02d", combo)
    }

    private func pulse(_ layer: CAShapeLayer) {
        let a = CABasicAnimation(keyPath: "transform.scale")
        a.fromValue = 1.0
        a.toValue = 1.15
        a.duration = 0.15
        a.autoreverses = true
        layer.add(a, forKey: "pulse")
    }

    // MARK: Score gain popper

    /// Floats a "+N" up out of the mouth of the funnel and fades it away.
    ///
    /// Called for each correct answer with the points that answer actually
    /// earned, so the streak multiplier is visible in the moment it pays out.
    /// It emits from the top bar and borrows that bar's magenta.
    ///
    /// The label travels past the top of the gauge, so nothing in the HUD
    /// hierarchy may clip it. `clipsToBounds` is false by default on `UIView`
    /// and is left that way here and on the gauge's parent.
    var scoreColors = [
        0: IgniterPalette.streakMagenta,
        1: IgniterPalette.streakBlue,
        2: IgniterPalette.streakLime,
        3: IgniterPalette.bracketYellow,
        4: IgniterPalette.fireAmber
    ]
    func emitScoreGain(_ amount: Int) {
        let randColor = Int.random(in: 0...4)
        let label = UILabel()
        label.text = "+\(amount)"
        label.font = AppFont.uiFont(size: 42)
        label.textColor = scoreColors[randColor]
        label.textAlignment = .center
        // Keeps the glyph readable where it crosses the pale funnel bars.
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.45
        label.sizeToFit()

        // Centre of the top bar, so it appears to burst out of that segment.
        let start = CGPoint(x: leftX + barWidth(0) / 2, y: topY + barHeight / 2)
        label.center = start
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        addSubview(label)

        // One keyframe pass so the rise, the pop and the fade can overlap
        // without separate animations fighting over `alpha`.
        UIView.animateKeyframes(withDuration: 1.15, delay: 0) {
            // Pop in and slightly overshoot...
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.15) {
                label.alpha = 1
                label.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }
            // ...settle back to full size.
            UIView.addKeyframe(withRelativeStartTime: 0.15, relativeDuration: 0.15) {
                label.transform = .identity
            }
            // Drift upward for the whole duration.
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                label.center = CGPoint(x: start.x, y: start.y - 64)
            }
            // Fade over the back half, so it's legible before it goes.
            UIView.addKeyframe(withRelativeStartTime: 0.45, relativeDuration: 0.55) {
                label.alpha = 0
            }
        } completion: { _ in
            label.removeFromSuperview()
        }
    }

    // MARK: Public API
    func setCombo(_ value: Int) {
        combo = min(max(0, value), barCount)
    }

    func incrementCombo(value: Int) {
        combo = min(max(0, value % (barCount + 1)), barCount)
    }

    func resetCombo() {
        combo = 0
    }

    func updateScore(_ value: Int) {
        score = value
    }
}
