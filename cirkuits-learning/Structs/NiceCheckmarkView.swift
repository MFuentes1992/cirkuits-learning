//
//  NiceCheckmarkView.swift
//  cirkuits-learning
//
//  The "Nice!" success flourish shown on a correct answer. Renders the
//  "Nice prompt" artwork (PNG) with a pop-in animation. Replaces the
//  previously hand-drawn CAShapeLayer checkmark.
//
import UIKit

class NiceCheckmarkView: UIView {

    private let imageView = UIImageView()

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

        imageView.image = ScreenAsset.uiImage("Nice prompt")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
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
