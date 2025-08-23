//
//  PixelCanvas.swift
//  Ray Reference
//
//  Created by Viktor Chernikov on 23.08.25.
//

import SwiftUI

struct PixelCanvas: View {
    let pixelSize: CGFloat = 1 // Point size per pixel
    let grid: [[Color]] // 2D color array
    
    var body: some View {
        Canvas { context, size in
            for (y, row) in grid.enumerated() {
                for (x, color) in row.enumerated() {
                    let rect = CGRect(
                        x: CGFloat(x) * pixelSize,
                        y: CGFloat(y) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(
            width: pixelSize * CGFloat(grid[0].count),
            height: pixelSize * CGFloat(grid.count)
        )
    }
}

extension V3 {
    func toColor() -> Color { Color(cgColor: .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)) }
}
