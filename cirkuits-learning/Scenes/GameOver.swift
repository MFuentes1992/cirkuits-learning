//
//  GameOver.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 23/03/26.
//
import SwiftUI
import MetalKit

struct GameOverView: View {
    let score: Int
    let highScore: Int
    var maxStreak: Int = 0
    let onRetry: () -> Void
    let onExit: () -> Void

    @State private var appeared = false

    private let ink   = Color(uiColor: IgniterPalette.navyInk)
    private let teal  = Color(uiColor: IgniterPalette.teal)
    private let retry = Color(uiColor: IgniterPalette.retryMagenta)
    private let exit  = Color(uiColor: IgniterPalette.exitLime)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            HexPatternBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("TIME'S UP")
                    .font(.jaro(52))
                    .foregroundColor(ink)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 28)

                VStack(spacing: 6) {
                    Text("Score")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(ink)

                    Text(String(format: "%03d", score))
                        .font(.jaro(108))
                        .foregroundColor(ink)

                    Text("MAX STREAK \(maxStreak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(ink)
                        .tracking(1)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer().frame(height: 28)

                Text("Best  \(String(format: "%03d", max(highScore, score)))")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(teal)
                    .cornerRadius(14)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                HStack(spacing: 20) {
                    Button(action: onRetry) {
                        Text("RETRY")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(retry)
                            .cornerRadius(14)
                    }
                    Button(action: onExit) {
                        Text("EXIT")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(exit)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
        }
    }
}

/// Faint pastel hexagon lattice used behind the GameOver content.
private struct HexPatternBackground: View {
    private let colors: [Color] = [
        Color(uiColor: IgniterPalette.hexPastelBlue),
        Color(uiColor: IgniterPalette.hexPastelPink),
        Color(uiColor: IgniterPalette.hexPastelPurple)
    ]

    var body: some View {
        Canvas { context, size in
            let r: CGFloat = 46
            let w = r * 2
            let h = r * sqrt(3)
            var row = 0
            var y = -h
            while y < size.height + h {
                let xOffset: CGFloat = (row % 2 == 0) ? 0 : r * 1.5
                var x = -w
                var col = 0
                while x < size.width + w {
                    let path = hexPath(centerX: x + xOffset, centerY: y, radius: r)
                    let color = colors[(row + col) % colors.count]
                    context.stroke(path, with: .color(color), lineWidth: 4)
                    x += r * 3
                    col += 1
                }
                y += h / 2
                row += 1
            }
        }
    }

    private func hexPath(centerX: CGFloat, centerY: CGFloat, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let pt = CGPoint(x: centerX + radius * cos(angle),
                             y: centerY + radius * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

class GameOverScene: SceneProtocol {
    private var hostingView: UIView?

    init(parentView: UIView, gameState: GameState, requestScene: @escaping (GameScenes) -> Void) {
        let view = GameOverView(
            score: gameState.Score,
            highScore: gameState.HighScore,
            maxStreak: gameState.MaxStreak,
            onRetry: { requestScene(.CountDown) },
            onExit: { exit(0) }
        )
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
        self.hostingView = hostingController.view
    }

    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {}
    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {}
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {}
    func play() {}
}

