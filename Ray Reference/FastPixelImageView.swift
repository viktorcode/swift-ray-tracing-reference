import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FastPixelImageView: View {
    let bitmap: [[Color]]
    let width: Int
    let height: Int
    let cgImage: CGImage?

    init(bitmap: [[Color]]) {
        self.bitmap = bitmap
        self.height = bitmap.count
        self.width = bitmap.first?.count ?? 0
        let startTime = CFAbsoluteTimeGetCurrent()
        self.cgImage = FastPixelImageView.makeCGImage(bitmap: bitmap, width: width, height: height)
        let renderingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("Time spent rendering: \(renderingTime)s")
    }

    var body: some View {
        if let cgImage {
            Image(decorative: cgImage, scale: 1, orientation: .up)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Color.black
        }
    }
    
    static func makeCGImage(bitmap: [[Color]], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0 else { return nil }
        var data = [UInt8](repeating: 0, count: width*height*4)
        for y in 0..<height {
            for x in 0..<width {
                #if canImport(UIKit)
                let color = UIColor(bitmap[y][x])
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                #elseif canImport(AppKit)
                let color = NSColor(bitmap[y][x])
                let rgbColor = color.usingColorSpace(.deviceRGB) ?? .black
                let r = rgbColor.redComponent
                let g = rgbColor.greenComponent
                let b = rgbColor.blueComponent
                let a = rgbColor.alphaComponent
                #endif
                let offset = 4*(y*width + x)
                data[offset] = UInt8((r*255).rounded())
                data[offset+1] = UInt8((g*255).rounded())
                data[offset+2] = UInt8((b*255).rounded())
                data[offset+3] = UInt8((a*255).rounded())
            }
        }
        let provider = CGDataProvider(data: Data(data) as CFData)
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width*4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
