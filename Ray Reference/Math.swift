import Foundation

// MARK: Number functions

func assertNaN(_ value: Float) {
    assert(!value.isNaN)
}

func filterNaN(_ value: Float) -> Float {
    return value.isNaN ? 0.0 : value
}

func clamp01(_ a: Float) -> Float {
    if a > 1.0 {
        return 1.0
    } else if a < 0.0 {
        return 0.0
    }
    return a
}

// MARK: V3
import simd

typealias V3 = SIMD3<Float>

extension V3 {
    var r: Float { get { x } set { x = newValue } }
    var g: Float { get { y } set { y = newValue } }
    var b: Float { get { z } set { z = newValue } }
}

func randomInUnitSphere(using generator: inout some RandomNumberGenerator) -> V3 {
    var v = V3(repeating: 0)

    repeat {
        v = 2.0 * V3(
            Float.random( in: 0..<1,using: &generator),
            Float.random(in: 0..<1, using: &generator),
            Float.random(in: 0..<1, using: &generator)
        ) - V3(repeating: 1.0)
    } while length_squared(v) >= 1.0

    return (v);
}

