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

    let nsSize = NSSize(width: px, height: px)
    let image = NSImage(size: nsSize, flipped: false) { rect in
        let cr = rect.width * 0.22
        let inset = rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02)
        let path = NSBezierPath(roundedRect: inset, xRadius: cr, yRadius: cr)

        let gradient = NSGradient(
            starting: NSColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 1.0),
            ending: NSColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0)
        )
        gradient?.draw(in: path, angle: -45)

        let symSize = rect.width * 0.5
        if let sun = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: symSize, weight: .thin)
            if let sym = sun.withSymbolConfiguration(config) {
                let w = CGFloat(sym.representations.first?.pixelsWide ?? Int(symSize))
                let h = CGFloat(sym.representations.first?.pixelsHigh ?? Int(symSize))
                let origin = NSPoint(x: (rect.width - w) / 2, y: (rect.height - h) / 2)
                NSColor.white.withAlphaComponent(0.95).set()
                sym.draw(in: NSRect(x: origin.x, y: origin.y, width: w, height: h))
            }
        }
        return true
    }

    guard let tiff = image.tiffRepresentation,
          let bmp = NSBitmapImageRep(data: tiff),
          let png = bmp.representation(using: .png, properties: [:]) else {
        print("Failed to render \(filename)")
        continue
    }
    try png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
    print("Generated \(filename) (\(px)x\(px))")
}

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
