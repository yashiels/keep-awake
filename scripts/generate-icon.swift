#!/usr/bin/env swift
import AppKit

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconsetPath = "\(outputDir)/AppIcon.iconset"

try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2),
    (128, 1), (128, 2), (256, 1), (256, 2),
    (512, 1), (512, 2),
]

for (size, scale) in sizes {
    let px = size * scale
    let suffix = scale == 1 ? "" : "@2x"
    let filename = "icon_\(size)x\(size)\(suffix).png"

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: px, height: px)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let rect = NSRect(x: 0, y: 0, width: px, height: px)
    let inset = rect.insetBy(dx: CGFloat(px) * 0.02, dy: CGFloat(px) * 0.02)
    let cr = CGFloat(px) * 0.22

    // Background gradient
    let path = NSBezierPath(roundedRect: inset, xRadius: cr, yRadius: cr)
    let gradient = NSGradient(colors: [
        NSColor(red: 1.0, green: 0.78, blue: 0.35, alpha: 1.0),
        NSColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0),
    ])
    gradient?.draw(in: path, angle: -45)

    // Draw sun symbol using Core Graphics text rendering of SF Symbol
    if let sun = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil) {
        let symPointSize = CGFloat(px) * 0.45
        let config = NSImage.SymbolConfiguration(pointSize: symPointSize, weight: .thin)
        if let configured = sun.withSymbolConfiguration(config) {
            let symSize = configured.size
            let x = (CGFloat(px) - symSize.width) / 2
            let y = (CGFloat(px) - symSize.height) / 2
            let drawRect = NSRect(x: x, y: y, width: symSize.width, height: symSize.height)

            // Tint white by drawing in white color
            NSColor.white.set()
            configured.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

            // Draw again with compositing to make it white
            let tinted = NSImage(size: symSize, flipped: false) { tintRect in
                configured.draw(in: tintRect)
                NSColor.white.setFill()
                tintRect.fill(using: .sourceAtop)
                return true
            }
            tinted.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 0.95)
        }
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed: \(filename)")
        continue
    }
    try pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
    print("Generated \(filename) (\(px)x\(px))")
}

// Convert to icns
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetPath, "-o", "\(outputDir)/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()

if iconutil.terminationStatus == 0 {
    try? FileManager.default.removeItem(atPath: iconsetPath)
    print("Created AppIcon.icns")
} else {
    print("iconutil failed with status \(iconutil.terminationStatus)")
}
