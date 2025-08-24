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
    let pixels: [[Color]] = raytrace().map { row in row.map { $0.toColor() } }

    var body: some View {
        FastPixelImageView(bitmap: pixels)
    }
}

extension V3 {
    func toColor() -> Color { Color(cgColor: .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)) }
}

#Preview {
    ContentView()
}
