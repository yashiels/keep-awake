import AppKit

enum IconGenerator {
    static func generateIconSet(outputDir: String) {
        let sizes: [(Int, Int)] = [
            (16, 1), (16, 2), (32, 1), (32, 2),
            (128, 1), (128, 2), (256, 1), (256, 2),
            (512, 1), (512, 2),
        ]

        let fm = FileManager.default
        let iconsetPath = "\(outputDir)/AppIcon.iconset"
        try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

        for (size, scale) in sizes {
            let pixelSize = size * scale
            let suffix = scale == 1 ? "" : "@2x"
            let filename = "icon_\(size)x\(size)\(suffix).png"
            if let image = renderIcon(pixelSize: pixelSize) {
                let path = "\(iconsetPath)/\(filename)"
                savePNG(image: image, to: path)
            }
        }
    }

    private static func renderIcon(pixelSize: Int) -> NSImage? {
        let size = NSSize(width: pixelSize, height: pixelSize)
        let image = NSImage(size: size, flipped: false) { rect in
            let cornerRadius = rect.width * 0.22

            // Background gradient (warm amber to soft gold)
            let path = NSBezierPath(roundedRect: rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02), xRadius: cornerRadius, yRadius: cornerRadius)
            let gradient = NSGradient(
                starting: NSColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 1.0),
                ending: NSColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0)
            )
            gradient?.draw(in: path, angle: -45)

            // Sun symbol
            let symbolSize = rect.width * 0.55
            if let sunImage = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .light)
                if let configured = sunImage.withSymbolConfiguration(config) {
                    let rep = configured.representations.first
                    let imgWidth = rep?.pixelsWide ?? Int(symbolSize)
                    let imgHeight = rep?.pixelsHigh ?? Int(symbolSize)
                    let drawSize = NSSize(width: CGFloat(imgWidth), height: CGFloat(imgHeight))
                    let origin = NSPoint(
                        x: (rect.width - drawSize.width) / 2,
                        y: (rect.height - drawSize.height) / 2
                    )

                    NSColor.white.withAlphaComponent(0.95).setFill()
                    configured.draw(in: NSRect(origin: origin, size: drawSize),
                                    from: .zero,
                                    operation: .sourceOver,
                                    fraction: 1.0)
                }
            }

            return true
        }
        return image
    }

    private static func savePNG(image: NSImage, to path: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
        try? pngData.write(to: URL(fileURLWithPath: path))
    }
}
