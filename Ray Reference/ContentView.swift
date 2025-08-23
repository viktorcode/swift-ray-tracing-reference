//
//  ContentView.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 23.08.25.
//

import SwiftUI

struct ContentView: View {
    let pixels: [[Color]] = raytrace().map { row in row.map { $0.toColor() } }

    var body: some View {
        PixelCanvas(grid: pixels)
    }
}

#Preview {
    ContentView()
}
