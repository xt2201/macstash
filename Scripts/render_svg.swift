import AppKit

let args = CommandLine.arguments
guard args.count >= 5 else {
    fputs("Usage: render_svg <input.svg> <output.png> <width> <height>\n", stderr)
    exit(1)
}

let inPath = args[1]
let outPath = args[2]
guard let width = Int(args[3]), let height = Int(args[4]), width > 0, height > 0 else {
    fputs("Invalid dimensions: \(args[3])x\(args[4])\n", stderr)
    exit(1)
}

guard let image = NSImage(contentsOfFile: inPath) else {
    fputs("Error: Could not load SVG from \(inPath)\n", stderr)
    exit(1)
}

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Error: Could not allocate NSBitmapImageRep\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    fputs("Error: Could not create NSGraphicsContext\n", stderr)
    exit(1)
}
NSGraphicsContext.current = context
context.imageInterpolation = .high

// Initialize transparent canvas
NSColor.clear.set()
NSRect(x: 0, y: 0, width: width, height: height).fill()

image.draw(
    in: NSRect(x: 0, y: 0, width: width, height: height),
    from: NSRect(origin: .zero, size: image.size),
    operation: .sourceOver,
    fraction: 1.0
)
NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fputs("Error: Failed to encode PNG\n", stderr)
    exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outPath))
} catch {
    fputs("Error writing to \(outPath): \(error)\n", stderr)
    exit(1)
}
