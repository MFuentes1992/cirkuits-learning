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
    let onRetry: () -> Void
    let onExit: () -> Void

    @State private var appeared = false

    private let purple = Color(red: 0.423, green: 0.231, blue: 0.66)

    var body: some View {
        ZStack {
            purple.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("TIME'S UP")
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 2, y: 2)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 8) {
                    Text("SCORE")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(5)

                    Text(String(format: "%03d", score))
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)

                    if highScore > 0 {
                        Text("BEST  \(String(format: "%03d", highScore))")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onRetry) {
                        Text("RETRY")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    Button(action: onExit) {
                        Text("EXIT")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 52)
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

class GameOverScene: SceneProtocol {
    private var hostingView: UIView?

    init(parentView: UIView, gameState: GameState, requestScene: @escaping (GameScenes) -> Void) {
        let view = GameOverView(
            score: gameState.Score,
            highScore: gameState.HighScore,
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
}

