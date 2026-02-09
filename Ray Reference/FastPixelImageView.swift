import SwiftUI
import CoreGraphics

struct FastPixelImageView: View {
    let cgImage: CGImage?

    init(bitmap: [[V3]]) {
        let height = bitmap.count
        let width = bitmap.first?.count ?? 0
        let startTime = CFAbsoluteTimeGetCurrent()
        self.cgImage = FastPixelImageView.makeCGImage(bitmap: bitmap, width: width, height: height)
        let renderingTime = CFAbsoluteTimeGetCurrent() - startTime
        print("Time spent rendering: \(String(format: "%.3f", renderingTime * 1000)) ms")
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
    
    static func makeCGImage(bitmap: [[V3]], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0 else { return nil }
        var data = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let offset = 4 * (y * width + x)
                let color = bitmap[y][x]
                data[offset] = UInt8((color.r * 255).rounded())
                data[offset+1] = UInt8((color.g * 255).rounded())
                data[offset+2] = UInt8((color.b * 255).rounded())
                data[offset+3] = UInt8(255)
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
