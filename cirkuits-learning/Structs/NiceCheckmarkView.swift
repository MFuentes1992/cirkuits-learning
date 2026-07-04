//
//  NiceCheckmarkView.swift
//  cirkuits-learning
//
//  The "Nice!" success flourish shown on a correct answer: a rotated
//  teal check frame with a white tick, offset multicolour outlines and
//  a teal speech tag. Replaces the old green "✅ Good!" label.
//
import UIKit

class NiceCheckmarkView: UIView {

    private let rotation: CGFloat = -8 * .pi / 180

    // Offset outline frames (drawn behind the main frame)
    private let cyanFrame   = CAShapeLayer()
    private let purpleFrame = CAShapeLayer()
    private let limeFrame    = CAShapeLayer()
    private let blueFrame    = CAShapeLayer()

    // Main teal frame + drop shadow + tick
    private let shadowFrame = CAShapeLayer()
    private let mainFrame   = CAShapeLayer()
    private let tick        = CAShapeLayer()

    // "Nice!" tag
    private let tagView = UIView()
    private let tagLabel = UILabel()

    private let content = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        content.backgroundColor = .clear
        addSubview(content)

        // Order: offset outlines first, then shadow, then main frame, then tick.
        [cyanFrame, purpleFrame, limeFrame, blueFrame].forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 6
            $0.lineJoin = .round
            content.layer.addSublayer($0)
        }
        cyanFrame.strokeColor   = IgniterPalette.checkCyan.cgColor
        purpleFrame.strokeColor = IgniterPalette.checkPurple.cgColor
        limeFrame.strokeColor    = IgniterPalette.checkLime.cgColor
        blueFrame.strokeColor    = IgniterPalette.checkBlue.cgColor

        shadowFrame.fillColor = UIColor.clear.cgColor
        shadowFrame.strokeColor = IgniterPalette.checkShadow.cgColor
        shadowFrame.lineWidth = 22
        shadowFrame.lineJoin = .round
        content.layer.addSublayer(shadowFrame)

        mainFrame.fillColor = UIColor.clear.cgColor
        mainFrame.strokeColor = IgniterPalette.teal.cgColor
        mainFrame.lineWidth = 22
        mainFrame.lineJoin = .round
        content.layer.addSublayer(mainFrame)

        tick.fillColor = UIColor.clear.cgColor
        tick.strokeColor = UIColor.white.cgColor
        tick.lineWidth = 34
        tick.lineCap = .round
        tick.lineJoin = .round
        content.layer.addSublayer(tick)

        // "Nice!" tag
        tagView.backgroundColor = IgniterPalette.teal
        tagView.layer.cornerRadius = 14
        tagView.layer.shadowColor = IgniterPalette.checkShadow.cgColor
        tagView.layer.shadowOffset = CGSize(width: 3, height: 5)
        tagView.layer.shadowRadius = 0
        tagView.layer.shadowOpacity = 1
        content.addSubview(tagView)

        tagLabel.text = "Nice!"
        tagLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        tagLabel.textColor = .white
        tagLabel.textAlignment = .center
        tagView.addSubview(tagLabel)

        content.transform = CGAffineTransform(rotationAngle: rotation)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        content.transform = .identity
        content.frame = bounds

        // Frame geometry in the (unrotated) content space.
        let frameRect = CGRect(x: bounds.width * 0.10, y: bounds.height * 0.18,
                               width: bounds.width * 0.62, height: bounds.height * 0.46)
        let framePath = UIBezierPath(roundedRect: frameRect, cornerRadius: 10).cgPath

        cyanFrame.path   = framePath
        purpleFrame.path = framePath
        limeFrame.path    = framePath
        blueFrame.path    = framePath
        shadowFrame.path  = framePath
        mainFrame.path    = framePath

        // Nudge the thin outlines out to the classic offset-print look.
        cyanFrame.transform   = CATransform3DMakeTranslation(-16, -2, 0)
        purpleFrame.transform = CATransform3DMakeTranslation(-2, -16, 0)
        limeFrame.transform    = CATransform3DMakeTranslation(16, -14, 0)
        blueFrame.transform    = CATransform3DMakeTranslation(18, 10, 0)
        shadowFrame.transform  = CATransform3DMakeTranslation(8, 10, 0)

        // White tick inside the frame.
        let t = UIBezierPath()
        t.move(to: CGPoint(x: frameRect.minX + frameRect.width * 0.18,
                           y: frameRect.minY + frameRect.height * 0.52))
        t.addLine(to: CGPoint(x: frameRect.minX + frameRect.width * 0.42,
                              y: frameRect.minY + frameRect.height * 0.78))
        t.addLine(to: CGPoint(x: frameRect.minX + frameRect.width * 0.86,
                              y: frameRect.minY + frameRect.height * 0.12))
        tick.path = t.cgPath

        // "Nice!" tag, lower-right, overlapping the frame corner.
        let tagW: CGFloat = 128, tagH: CGFloat = 56
        tagView.frame = CGRect(x: frameRect.maxX - 26,
                               y: frameRect.maxY - tagH * 0.35,
                               width: tagW, height: tagH)
        tagLabel.frame = tagView.bounds

        content.transform = CGAffineTransform(rotationAngle: rotation)
    }

    /// Pop-in animation used when a correct answer lands.
    func play() {
        layer.removeAllAnimations()
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseOut, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }, completion: { _ in
            UIView.animate(withDuration: 0.12, animations: {
                self.transform = .identity
            }, completion: { _ in
                UIView.animate(withDuration: 0.4, delay: 0.5, options: .curveEaseIn, animations: {
                    self.alpha = 0
                })
            })
        })
    }
}
