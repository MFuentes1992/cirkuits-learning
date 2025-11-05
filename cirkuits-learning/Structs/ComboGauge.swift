//
//  ComboGauge.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 03/11/25.
//
import UIKit

class ComboGauge: UIView {
    private let maxCombo = 4
    private var combo: Int = 0 {
        didSet {
            updateGauge()
        }
    }
    
    private var barLayers: [CAShapeLayer] = []
    private var barOutlineLayers: [CAShapeLayer] = []
    private let badgeLabel = UILabel()
    private let comboLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGauge()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGauge()
    }
    
    private func setupGauge() {
        backgroundColor = .clear
        
        // Create 5 parallelogram bars
        for i in 0..<maxCombo {
            // Filled bar layer
            let barLayer = CAShapeLayer()
            barLayer.fillColor = UIColor.clear.cgColor
            barLayer.shadowColor = UIColor(red: 0.78, green: 1.0, blue: 0, alpha: 1).cgColor
            barLayer.shadowRadius = 8
            barLayer.shadowOpacity = 0
            barLayer.shadowOffset = .zero
            layer.addSublayer(barLayer)
            barLayers.append(barLayer)
            
            // Outline layer
            let outlineLayer = CAShapeLayer()
            outlineLayer.strokeColor = UIColor.white.cgColor
            outlineLayer.lineWidth = 2
            outlineLayer.fillColor = UIColor.clear.cgColor
            layer.addSublayer(outlineLayer)
            barOutlineLayers.append(outlineLayer)
        }
        
        // Badge circle with multiplier
        let badge = UIView()
        badge.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.86, alpha: 1)
        badge.layer.cornerRadius = 30
        badge.layer.shadowColor = UIColor.black.cgColor
        badge.layer.shadowOffset = CGSize(width: 2, height: 2)
        badge.layer.shadowRadius = 4
        badge.layer.shadowOpacity = 0.5
        addSubview(badge)
        
        badgeLabel.font = .systemFont(ofSize: 20, weight: .black)
        badgeLabel.textColor = UIColor(red: 0.17, green: 0.09, blue: 0.06, alpha: 1)
        badgeLabel.textAlignment = .center
        badgeLabel.text = "x00"
        badge.addSubview(badgeLabel)
        
        // "COMBO" text
        comboLabel.text = "COMBO"
        comboLabel.font = .systemFont(ofSize: 24, weight: .black)
        comboLabel.textColor = .white
        comboLabel.textAlignment = .center
        comboLabel.layer.shadowColor = UIColor.black.cgColor
        comboLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        comboLabel.layer.shadowRadius = 2
        comboLabel.layer.shadowOpacity = 0.5
        addSubview(comboLabel)
        
        // Layout
        badge.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        comboLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 60),
            badge.heightAnchor.constraint(equalToConstant: 60),
            badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -25),
            
            badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            badgeLabel.widthAnchor.constraint(equalTo: badge.widthAnchor),
            
            comboLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            comboLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            comboLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarPaths()
    }
    
    private func updateBarPaths() {
        let barHeight: CGFloat = 18
        let barSpacing: CGFloat = 8
        let barWidth: CGFloat = 100
        let startY: CGFloat = 0
        let skew: CGFloat = 8
        
        for i in 0..<maxCombo {
            let y = startY + CGFloat(i) * (barHeight + barSpacing)
            let path = createParallelogramPath(x: 15, y: y, width: barWidth, height: barHeight)
            
            barLayers[i].path = path
            barOutlineLayers[i].path = path
        }
    }
    
    private func createParallelogramPath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height))
        path.close()
        return path.cgPath
    }
    
    private func updateGauge() {
        // Update bars
        for i in 0..<maxCombo {
            let barNumber = maxCombo - i
            let isFilled = combo >= barNumber
            
            if isFilled {
                barLayers[i].fillColor = UIColor(red: 0.78, green: 1.0, blue: 0, alpha: 1).cgColor
                barLayers[i].shadowOpacity = 0.6
                
                // Animate the newly filled bar
                if combo == barNumber {
                    animateBar(barLayers[i])
                }
            } else {
                barLayers[i].fillColor = UIColor.clear.cgColor
                barLayers[i].shadowOpacity = 0
            }
        }
        
        // Update badge text
        badgeLabel.text = String(format: "x%02d", combo)
    }
    
    private func animateBar(_ layer: CAShapeLayer) {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.15
        scaleAnimation.duration = 0.15
        scaleAnimation.autoreverses = true
        layer.add(scaleAnimation, forKey: "pulse")
    }
    
    // Public method to update combo
    func setCombo(_ value: Int) {
        combo = min(max(0, value), maxCombo)
    }
    
    func incrementCombo() {
        if combo < maxCombo {
            combo += 1
        }
    }
    
    func resetCombo() {
        combo = 0
    }
}
