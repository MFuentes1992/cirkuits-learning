//
//  Expenrimental.swift
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

    /// Point the camera orbits — recomputed from the letters actually on stage
    /// rather than assumed, since the layout offsets glyphs by +20 in Y.
    private var target = SIMD3<Float>(0, 9, 0)
    private var yaw: Float = 0
    private var pitch: Float = 0
    private var radius: Float = 90

    /// Pitch stops just short of straight up/down: `makeLookAtMatrix` builds its
    /// basis with `cross(up, z)`, which collapses when the view direction
    /// becomes parallel to the up vector.
    private let maxPitch: Float = .pi / 2 - 0.01
    private let minRadius: Float = 15
    private let maxRadius: Float = 400
    /// Screen points to radians — a drag the width of the view is about a half turn.
    private let orbitSensitivity: Float = 0.01

    // MARK: Exit animation

    /// Words to cycle through. Restricted to glyphs regenerated from Jaro so the
    /// sandbox isn't showing a mix of old and new geometry.
    var words = ["hola", "halo", "ola", "loa"]
    private var wordIndex = 0

    /// How long a word sits still before it flies out.
    private let dwellDuration: Double = 2.0
    /// Flight time for a single letter.
    private let exitDuration: Float = 0.85
    /// Delay between consecutive letters leaving, so they peel off in sequence.
    private let exitStagger: Float = 0.08
    /// How far a letter travels toward the camera. Must exceed `radius` so the
    /// glyph passes the eye and is clipped, rather than stopping in view.
    private var exitTravel: Float { radius + 60 }
    /// Total tumble over the flight.
    private let exitSpin: Float = .pi * 1.6

    private enum Phase {
        case dwelling
        case exiting
    }
    private var phase: Phase = .dwelling
    private var phaseStart: CFTimeInterval = CACurrentMediaTime()

    /// Length of the whole exit, including the last letter's stagger.
    private var exitTotalDuration: Float {
        exitDuration + exitStagger * Float(max(0, currentLetterCount - 1))
    }
    private var currentLetterCount = 0

    init(device: MTLDevice, view: MTKView) {
        self.wordRenderer = WordRenderer(device: device, screenWidth: 400)
        let cameraSettings = CameraSettings(
            eye: SIMD3<Float>(0,0,100),
            center: SIMD3<Float>(0,0,0),
            up: SIMD3<Float>(0,1,0),
            fovDegrees: 60.0,
            aspectRatio: 19.5/9,
            nearZ: 1.0,
            farZ: 1000.0)
        self.camera = Camera(settings: cameraSettings)

        showWord(words[0])

        // The renderer asks us for a transform per letter every frame; that's
        // where the exit animation lives, so the layout manager stays unaware.
        wordRenderer.letterTransformModifier = { [weak self] index, letter, layout in
            guard let self else { return layout }
            return self.exitTransform(index: index, letter: letter, layout: layout)
        }

        updateCameraPosition()
    }

    private func showWord(_ word: String) {
        wordRenderer.CurrentFoo = WordFoo(Word: word, Reward: 0)
        currentLetterCount = word.count
        target = wordRenderer.wordCenter
        updateCameraPosition()
    }

    // MARK: Animation

    /// Progress 0...1 for one letter, accounting for its stagger.
    private func exitProgress(index: Int, elapsed: Float) -> Float {
        let start = exitStagger * Float(index)
        return min(1, max(0, (elapsed - start) / exitDuration))
    }

    /// Ease-in-back: pulls the letter slightly away from the viewer before it
    /// launches, which reads as a wind-up and keeps the departure from feeling
    /// like a cut.
    private func easeInBack(_ t: Float) -> Float {
        let c1: Float = 1.70158
        let c3: Float = c1 + 1
        return c3 * t * t * t - c1 * t * t
    }

    /// Smoothstep, so the tumble starts and ends gently rather than snapping
    /// into full rotation speed.
    private func easeInOut(_ t: Float) -> Float {
        t * t * (3 - 2 * t)
    }

    /// Builds the drawn matrix for one letter: spin about its own centre, then
    /// translate along the camera's view axis toward the eye.
    private func exitTransform(index: Int, letter: Letter, layout: simd_float4x4) -> simd_float4x4 {
        guard phase == .exiting else { return layout }

        let elapsed = Float(CACurrentMediaTime() - phaseStart)
        let t = exitProgress(index: index, elapsed: elapsed)
        guard t > 0 else { return layout }

        // Toward the viewer means along the eye-to-target axis, so the exit
        // still reads correctly after the camera has been orbited.
        let toEye = normalize(camera.settings.eye - target)
        let travel = toEye * (easeInBack(t) * exitTravel)

        let spin = easeInOut(t) * exitSpin
        // Tumble on a tilted axis so it doesn't look like a flat spin.
        let axis = normalize(SIMD3<Float>(0.35, 1, 0.15))
        let rotation = matrix_rotation(radians: spin, axis: axis)

        // Rotate about the glyph's own centre: shift to the origin, spin, shift
        // back — otherwise it swings around the layout origin instead.
        let centre = letter.modelCenter
        let toOrigin = float4x4(translation: -centre)
        let fromOrigin = float4x4(translation: centre)

        return float4x4(translation: travel) * layout * fromOrigin * rotation * toOrigin
    }

    private func advancePhase() {
        let now = CACurrentMediaTime()
        switch phase {
        case .dwelling:
            if now - phaseStart >= dwellDuration {
                phase = .exiting
                phaseStart = now
            }
        case .exiting:
            if Float(now - phaseStart) >= exitTotalDuration {
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
        radius = 90
        updateCameraPosition()
    }

    func encode(encoder: MTLRenderCommandEncoder, view: MTKView) {
        advancePhase()

        // Match the real drawable instead of the hardcoded 19.5:9, otherwise the
        // glyph is subtly stretched and the geometry can't be judged.
        let size = view.drawableSize
        if size.height > 0 {
            camera.settings.aspectRatio = Float(size.width / size.height)
        }
        self.wordRenderer.render(encoder: encoder, viewMatrix: camera.viewMatrix, projectionMatrix: camera.projectionMatrix)
    }

    func play() {

    }
}
