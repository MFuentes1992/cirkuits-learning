//
//  Sandbox.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 31/07/26.
//
import MetalKit
import QuartzCore

/// Inspection scene: renders a word and lets you orbit around it.
/// Drag to rotate, pinch to zoom — the letters never move for the camera, so
/// the geometry is seen exactly as the game will draw it.
///
/// Cycles through `words` so the exit animation plays continuously.
class Sandbox: SceneProtocol {
    private var wordRenderer: WordRenderer!
    private var camera: Camera!

    // MARK: Orbit state

    /// Point the camera orbits — recomputed from the letters actually on stage.
    private var target = SIMD3<Float>(0, 0, 0)
    private var yaw: Float = 0
    private var pitch: Float = 0
    private var radius: Float = 90

    // MARK: Framing

    /// Head-on distance the layout is fitted for. The text box is computed once
    /// for this view, so pinch-zooming inspects the result instead of re-flowing it.
    private let framingRadius: Float = 90
    /// Fraction of the visible frustum the text may fill, leaving a border.
    private let framingMargin: Float = 0.85
    /// Aspect the current layout was fitted for; a change triggers a re-layout.
    private var layoutAspect: Float = 0

    /// Pitch stops just short of straight up/down: `makeLookAtMatrix` builds its
    /// basis with `cross(up, z)`, which collapses when the view direction
    /// becomes parallel to the up vector.
    private let maxPitch: Float = .pi / 2 - 0.01
    private let minRadius: Float = 15
    private let maxRadius: Float = 400
    /// Screen points to radians — a drag the width of the view is about a half turn.
    private let orbitSensitivity: Float = 0.01

    // MARK: Exit animation

    /// Words to cycle through. The phrases exercise wrapping and fit.
    var words = ["hola", "halo", "She is happy", "ola", "They are very happy", "loa", "We are kind"]
    private var wordIndex = 0

    /// How long a word sits still before it flies out.
    private let dwellDuration: Double = 2.0
    private let exitAnimation = WordExitAnimation()

    private enum Phase {
        case dwelling
        case exiting
    }
    private var phase: Phase = .dwelling
    private var phaseStart: CFTimeInterval = CACurrentMediaTime()

    init(device: MTLDevice, view: MTKView) {
        self.wordRenderer = WordRenderer(device: device)
        let cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: 19.5/9,
            nearZ: 1.0,
            farZ: 1000.0)
        self.camera = Camera(settings: cameraSettings)

        let size = view.drawableSize
        fitLayout(aspect: size.height > 0 ? Float(size.width / size.height) : 9 / 19.5)
        showWord(words[0])

        // The renderer asks us for a transform per letter every frame; that's
        // where the exit animation lives, so the layout manager stays unaware.
        wordRenderer.letterTransformModifier = { [weak self] index, letter, layout in
            guard let self else { return layout }
            // Toward the viewer means along the eye-to-target axis, so the exit
            // still reads correctly after the camera has been orbited.
            return self.exitAnimation.transform(
                index: index, letter: letter, layout: layout,
                toEye: normalize(self.camera.settings.eye - self.target),
                travel: self.radius + 60)
        }

        updateCameraPosition()
    }

    private func showWord(_ word: String) {
        wordRenderer.CurrentFoo = WordFoo(Word: word, Reward: 0)
        target = wordRenderer.wordCenter
        updateCameraPosition()
    }

    /// Sizes the wrapped layout to the frustum slice at `framingRadius`, where
    /// the text plane sits when the view is reset.
    private func fitLayout(aspect: Float) {
        layoutAspect = aspect
        camera.settings.aspectRatio = aspect
        let visibleHeight = 2 * framingRadius * tan(radians_from_degrees(camera.settings.fovDegrees) / 2)
        wordRenderer.layoutMode = .wrapped(
            maxWidth: visibleHeight * aspect * framingMargin,
            maxHeight: visibleHeight * framingMargin)
    }

    // MARK: Animation

    private func advancePhase() {
        let now = CACurrentMediaTime()
        switch phase {
        case .dwelling:
            if now - phaseStart >= dwellDuration {
                phase = .exiting
                exitAnimation.start(letterCount: words[wordIndex].count)
            }
        case .exiting:
            if exitAnimation.isFinished {
                exitAnimation.stop()
                wordIndex = (wordIndex + 1) % words.count
                showWord(words[wordIndex])
                phase = .dwelling
                phaseStart = now
            }
        }
    }

    // MARK: Gestures

    func handlePanGesture(gesture: UIPanGestureRecognizer, location: CGPoint) {
        guard gesture.state == .began || gesture.state == .changed else { return }

        let translation = gesture.translation(in: gesture.view)
        // Camera orbits against the drag, so the letter appears to follow the
        // finger rather than run from it.
        yaw -= Float(translation.x) * orbitSensitivity
        pitch += Float(translation.y) * orbitSensitivity
        pitch = min(maxPitch, max(-maxPitch, pitch))

        // Consume the translation so the next callback reports only new movement.
        gesture.setTranslation(.zero, in: gesture.view)
        updateCameraPosition()
    }

    func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { return }

        // Pinching apart (scale > 1) should close the distance.
        radius = min(maxRadius, max(minRadius, radius / Float(gesture.scale)))

        gesture.scale = 1
        updateCameraPosition()
    }

    /// Rebuilds the eye position from yaw/pitch/radius as a spherical offset
    /// from `target`.
    private func updateCameraPosition() {
        let cosPitch = cos(pitch)
        let offset = SIMD3<Float>(
            radius * cosPitch * sin(yaw),
            radius * sin(pitch),
            radius * cosPitch * cos(yaw)
        )
        camera.settings.eye = target + offset
        camera.settings.center = target
    }

    /// Frames the word head-on again.
    func resetView() {
        yaw = 0
        pitch = 0
        radius = framingRadius
        updateCameraPosition()
    }

    func encode(encoder: MTLRenderCommandEncoder, view: MTKView) {
        advancePhase()

        // Match the real drawable instead of the hardcoded 19.5:9, otherwise the
        // glyph is subtly stretched and the geometry can't be judged.
        let size = view.drawableSize
        if size.height > 0 {
            let aspect = Float(size.width / size.height)
            if abs(aspect - layoutAspect) > 0.001 {
                fitLayout(aspect: aspect)
                showWord(words[wordIndex])
            }
        }
        self.wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }

    func play() {

    }
}
