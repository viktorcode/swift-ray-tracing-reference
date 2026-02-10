//
//  ContentView.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 23.08.25.
//

import SwiftUI
import simd

struct ContentView: View {
    let nx: Int = 600
    let ny: Int = 300
    let lookAt: V3 = .init(0.0, 0.3, 0.0)
    let k: V3 = .init(0, 1, 0)
    let vUp = V3(0.18, 1, 0)
    let omega: Float = (2 * Float.pi) / 300

    @State var data: [[V3]] = []
    @State var pixels: [[V3]] = []

    @State var lookFrom: V3 = .init(0.001, 0.39, -1.0)
    @State var ellipsePhase: Float = 0

    @FocusState private var focused: Bool

    var body: some View {
        FastPixelImageView(bitmap: pixels)
            .focusable()
            .focused($focused)
            .onKeyPress { press in
                switch press.key {
                case .leftArrow: rotateCamera(by: -omega)
                case .rightArrow: rotateCamera(by: omega)
                default: break
                }
                return .handled
            }
            .task {
                focused = true
                // Render indefinitely
                await doWork()
            }
    }

    func doWork() async {
        let scene = setup()
        while !Task.isCancelled {
            await raytraceFrame(in: scene)
            pixels = data
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    func rotateCamera(by angle: Float) {
        let w = normalize(lookFrom - lookAt)
        let u = normalize(cross(vUp, w))
        let v = cross(w, u)
        // NOTE: (Kapsy) Rodrigues Rotation formula
        var vector = lookFrom
        vector = vector * cos(angle) + cross(k, vector) * sin(angle) + k * dot(k, v) * (1.0 - cos(angle))
        lookFrom = vector

        ellipsePhase += angle
    }
}

#Preview {
    ContentView()
}
