//
//  MenuScene.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 19/07/25.
//
import MetalKit
import SwiftUI

// MARK: - Palette

private enum MenuPalette {
    static let pink = Color(red: 0.97, green: 0.42, blue: 0.45)
    static let yellow = Color(red: 0.97, green: 0.80, blue: 0.30)
}

// MARK: - Asset loading

/// Loads a screen asset PNG. The artwork ships as loose PNGs (not an asset
/// catalog), which SwiftUI's `Image(_:)` cannot resolve — so look the image
/// up by name and fall back to a direct bundle path.
private func menuAsset(_ name: String) -> Image {
    if let image = UIImage(named: name) ?? bundlePNG(name) {
        return Image(uiImage: image)
    }
    return Image(systemName: "exclamationmark.triangle")
}

private func bundlePNG(_ name: String) -> UIImage? {
    guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
    return UIImage(contentsOfFile: path)
}

// MARK: - Scrolling "IGNITER///" ticker

/// Horizontally scrolling ticker built from two side-by-side copies of the
/// tiled text strip, looped seamlessly.
private struct MenuTicker: View {
    let width: CGFloat
    @State private var offset: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            menuAsset("Igniter_BGP3").resizable().scaledToFit().frame(width: width)
            menuAsset("Igniter_BGP3").resizable().scaledToFit().frame(width: width)
        }
        .offset(x: offset)
        .frame(width: width, alignment: .leading)
        .clipped()
        .scaleEffect(2.0)
        .onAppear {
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                offset = -width
            }
        }
    }
}

// MARK: - Bottom zigzag decoration

/// The layered zigzag bands at the bottom of the screen: a yellow band
/// poking above a pink band, with the scrolling ticker along the bottom edge.
private struct BottomDecoration: View {
    let width: CGFloat

    /// Natural aspect ratio of the zigzag band artwork (3175 × 661).
    private let bandAspect: CGFloat = 3175.0 / 661.0

    var body: some View {
        let bandHeight = width / bandAspect
        ZStack(alignment: .bottom) {
            menuAsset("Igniter_BGP1")
                .resizable().scaledToFit().frame(width: width)
//                .offset(y: -bandHeight * 0.5)

            menuAsset("Igniter_BGP2")
                .resizable().scaledToFit().frame(width: width)
//                .offset(y: -bandHeight * 0.6)
            
            MenuTicker(width: width)
               .offset(y: -bandHeight * 0.2)
        }
        .frame(width: width, height: bandHeight, alignment: .bottom)
    }
}

// MARK: - Menu view

struct MenuView: View {
    /// Invoked when the player taps Play — advances to the countdown.
    let onPlay: () -> Void

    @State private var appeared = false
    @State private var flameBreath = false
    @State private var wavePulse = false
    @State private var logoSway = false
    @State private var playPulse = false
    @State private var playPressed = false
    @State private var arrowNudge = false
    @State private var backPressed = false
    @State private var medalPressed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                menuAsset("IgniterCBG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                VStack(spacing: 10) {
                    Spacer().frame(height: 88)
                    flameSection
                    logo
                    Spacer()
                    playRow
                    Spacer().frame(height: 20)
                    secondaryButtons
                    Spacer()
                    BottomDecoration(width: geo.size.width)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: startAnimations)
    }

    // MARK: Flame + sound waves

    private var flameSection: some View {
        ZStack {
            // Staggered ripples on each side — N ripples per side, evenly
            // spaced in time, period == N * stagger so the cadence repeats
            // seamlessly.
            ripple(rightSide: false, color: MenuPalette.yellow, delay: 0.0)
            ripple(rightSide: false, color: MenuPalette.pink,   delay: 0.6)
            //ripple(rightSide: false, color: MenuPalette.yellow, delay: 1.2)
            ripple(rightSide: true,  color: MenuPalette.yellow, delay: 0.0)
            ripple(rightSide: true,  color: MenuPalette.pink,   delay: 0.6)
            //ripple(rightSide: true,  color: MenuPalette.yellow, delay: 1.5)

            menuAsset("Igniter_IMG")
                .resizable()
                .scaledToFit()
                .frame(width: 96)
        }
        .frame(height: 200)
        .scaleEffect(appeared ? 1 : 0.4)
        .opacity(appeared ? 1 : 0)
    }

    /// A single sound-wave ripple. Starts close to the flame, expands outward,
    /// and fades to zero opacity — like a water ripple. The fade-to-invisible
    /// at the end of each cycle hides the snap-back to the starting state.
    private func ripple(rightSide: Bool, color: Color, delay: Double) -> some View {
        let period: Double = 1.8
        return Circle()
            .trim(from: 0.40, to: 0.60)
            .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .rotationEffect(.degrees(rightSide ? 180 : 0))
            .frame(width: 200, height: 200)
            .scaleEffect(wavePulse ? 1.5 : 0.3)
            .opacity(wavePulse ? 0.0 : 1.0)
            .animation(
                .easeOut(duration: period).delay(delay).repeatForever(autoreverses: false),
                value: wavePulse)
    }

    // MARK: Logo

    private var logo: some View {
        menuAsset("Igniter_Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 264)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
    }

    // MARK: Play button + arrows

    private var playRow: some View {
        HStack(spacing: 50) {
            // Arrows are decorative for now — there is no stage selection yet.
            menuAsset("Igniter_LeftArrow")
                .resizable().scaledToFit().frame(width: 38)
               .offset(x: arrowNudge ? -7 : 0)
                .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                           value: arrowNudge)

            Button(action: triggerPlay) {
                menuAsset("Igniter_Play")
                    .resizable().scaledToFit().frame(width: 150)
            }
            .buttonStyle(.plain)

            menuAsset("Igniter_RightArrow")
                .resizable().scaledToFit().frame(width: 38)
                .offset(x: arrowNudge ? 7 : 0)
                .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                           value: arrowNudge)
        }
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Back + medal

    private var secondaryButtons: some View {
        HStack {
            Spacer()
            circleButton(image: "Igniter_Back", pressed: $backPressed)
            Spacer()
            circleButton(image: "Igniter_Medal", pressed: $medalPressed)
            Spacer()
        }
        .padding(.horizontal, 3)
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
    }

    /// Decorative circular button with a press bounce — no destination yet.
    private func circleButton(image: String, pressed: Binding<Bool>) -> some View {
        Button {
            pressed.wrappedValue = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                pressed.wrappedValue = false
            }
        } label: {
            menuAsset(image).resizable().scaledToFit().frame(width: 62)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed.wrappedValue ? 0.85 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: pressed.wrappedValue)
    }

    // MARK: Actions

    private func startAnimations() {
        flameBreath = true
        wavePulse = true
        logoSway = true
        playPulse = true
        arrowNudge = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            appeared = true
        }
    }

    private func triggerPlay() {
        playPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            playPressed = false
            onPlay()
        }
    }
}

// MARK: - Scene

private extension UIView {
    /// Walks the responder chain to find the view controller owning this view.
    func owningViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController { return viewController }
            responder = current.next
        }
        return nil
    }
}

class MenuScene: SceneProtocol {
    private var hostingController: UIHostingController<MenuView>?

    init(parentView: UIView, gameState: GameState, requestScene: @escaping (GameScenes) -> Void) {
        let menu = MenuView(onPlay: { requestScene(.CountDown) })
        let hosting = UIHostingController(rootView: menu)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        // Parent the hosting controller so SwiftUI receives correct safe-area
        // insets — otherwise full-screen layout is offset.
        let parentVC = parentView.owningViewController()
        parentVC?.addChild(hosting)
        parentView.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: parentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
        hosting.didMove(toParent: parentVC)

        self.hostingController = hosting
    }

    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {}
    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {}
    func encode(encoder: any MTLRenderCommandEncoder, view: MTKView) {}
    func play() {}
}
