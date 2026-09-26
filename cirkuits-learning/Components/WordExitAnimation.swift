//
//  WordExitAnimation.swift
//  cirkuits-learning
//
//  Created by Marco Fuentes Jiménez on 26/09/26.
//
import QuartzCore
import simd

/// Letters peel off one after another, each tumbling about its own centre
/// while it flies toward — and past — the camera.
///
/// Plugs into `WordRenderer.letterTransformModifier` via `transform(...)`; the
/// layout itself is never touched, so stopping the animation restores the word.
final class WordExitAnimation {
    /// Flight time for a single letter.
    var duration: Float = 0.85
    /// Delay between consecutive letters leaving, so they peel off in sequence.
    var stagger: Float = 0.08
    /// Optional ceiling for the whole exit. The stagger shrinks so the last
    /// letter still lands in time — long phrases peel off faster rather than
    /// being cut off.
    var maxTotalDuration: Float?
    /// Total tumble over the flight.
    var spin: Float = .pi * 1.6

    private(set) var isRunning = false
    private var startTime: CFTimeInterval = 0
    private var letterCount = 0

    func start(letterCount: Int) {
        self.letterCount = letterCount
        startTime = CACurrentMediaTime()
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    /// Length of the whole exit, including the last letter's stagger.
    var totalDuration: Float {
        effectiveDuration + effectiveStagger * Float(max(0, letterCount - 1))
    }

    var isFinished: Bool {
        isRunning && elapsed >= totalDuration
    }

    private var elapsed: Float {
        Float(CACurrentMediaTime() - startTime)
    }

    private var effectiveDuration: Float {
        guard let cap = maxTotalDuration else { return duration }
        return min(duration, cap)
    }

    private var effectiveStagger: Float {
        guard let cap = maxTotalDuration, letterCount > 1 else { return stagger }
        let room = max(0, cap - effectiveDuration) / Float(letterCount - 1)
        return min(stagger, room)
    }

    /// Builds the drawn matrix for one letter: spin about its own centre, then
    /// translate along `toEye` by up to `travel`. `travel` must exceed the
    /// camera distance so the glyph passes the eye and is clipped, rather than
    /// stopping in view.
    func transform(index: Int, letter: Letter, layout: simd_float4x4,
                   toEye: SIMD3<Float>, travel: Float) -> simd_float4x4 {
        guard isRunning else { return layout }

        let start = effectiveStagger * Float(index)
        let t = min(1, max(0, (elapsed - start) / effectiveDuration))
        guard t > 0 else { return layout }

        let offset = toEye * (easeInBack(t) * travel)

        // Tumble on a tilted axis so it doesn't look like a flat spin.
        let axis = normalize(SIMD3<Float>(0.35, 1, 0.15))
        let rotation = matrix_rotation(radians: easeInOut(t) * spin, axis: axis)

        // Rotate about the glyph's own centre: shift to the origin, spin, shift
        // back — otherwise it swings around the layout origin instead.
        let centre = letter.modelCenter
        let toOrigin = float4x4(translation: -centre)
        let fromOrigin = float4x4(translation: centre)

        return float4x4(translation: offset) * layout * fromOrigin * rotation * toOrigin
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
}
