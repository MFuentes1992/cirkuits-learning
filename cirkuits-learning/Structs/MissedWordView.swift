import SwiftUI

class MissedWordView: UIView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }
    
    private func setUp() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        label.text = "Missed!"
        label.font = AppFont.uiFont(size: 52)
        label.textColor = IgniterPalette.white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth =  true
        label.minimumScaleFactor = 0.6
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
   
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
