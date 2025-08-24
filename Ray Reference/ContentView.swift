//
//  ContentView.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 23.08.25.
//

import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    let nx: Int = 600
    let ny: Int = 300
    let lookAt: V3 = .init(0.0, 0.3, 0.0)
    let k: V3 = .init(0, 1, 0)
    let omega: Float = (2 * Float.pi) / 300

    @State var data: [[V3]] = []
    @State var pixels: [[Color]] = []

    @State var lookFrom: V3 = .init(0.001, 0.39, -1.0)
    @State var ellipsePhase: Float = 0

    var body: some View {
        ZStack {
            FastPixelImageView(bitmap: pixels)
        }
        .task {
            setup()
            while !Task.isCancelled {
                raytraceFrame()
                pixels = data.map { row in row.map { $0.toColor() } }
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
    }
}

extension V3 {
    func toColor() -> Color { Color(cgColor: .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)) }
}

#Preview {
    ContentView()
}
