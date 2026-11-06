import AppKit

func renderAndSave(active: Bool, scale: CGFloat, path: String) {
    let ptSize = 18.0
    let pxSize = Int(ptSize * scale)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pxSize,
        pixelsHigh: pxSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let cg = ctx.cgContext
    cg.clear(CGRect(x: 0, y: 0, width: pxSize, height: pxSize))
    cg.scaleBy(x: scale, y: scale)

    let origin = CGPoint(x: 3.5, y: 3.5)

    // Corner Pivot Dot
    cg.setFillColor(NSColor.black.cgColor)
    cg.fillEllipse(in: CGRect(x: origin.x - 1.5, y: origin.y - 1.5, width: 3.0, height: 3.0))

    // Outer Track Arc (Radius 11.5pt, sweeping from 0 to 90 degrees)
    let trackRadius: CGFloat = 11.5
    let trackPath = CGMutablePath()
    trackPath.addArc(center: origin, radius: trackRadius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
    cg.addPath(trackPath)
    cg.setStrokeColor(NSColor.black.cgColor)
    cg.setLineWidth(1.75)
    cg.setLineCap(.round)
    cg.strokePath()

    if active {
        let activeRadius: CGFloat = 7.0
        let activePath = CGMutablePath()
        activePath.addArc(center: origin, radius: activeRadius, startAngle: 0, endAngle: .pi / 2, clockwise: false)
        cg.addPath(activePath)
        cg.setStrokeColor(NSColor.black.cgColor)
        cg.setLineWidth(2.0)
        cg.strokePath()

        let pipAngle = CGFloat.pi / 4
        let pipDist: CGFloat = 9.25
        let pipCenter = CGPoint(x: origin.x + pipDist * cos(pipAngle), y: origin.y + pipDist * sin(pipAngle))
        cg.fillEllipse(in: CGRect(x: pipCenter.x - 1.25, y: pipCenter.y - 1.25, width: 2.5, height: 2.5))
    } else {
        let angle = CGFloat.pi / 4
        let innerR: CGFloat = 5.5
        let outerR: CGFloat = 8.5
        let p1 = CGPoint(x: origin.x + innerR * cos(angle), y: origin.y + innerR * sin(angle))
        let p2 = CGPoint(x: origin.x + outerR * cos(angle), y: origin.y + outerR * sin(angle))
        cg.move(to: p1)
        cg.addLine(to: p2)
        cg.setLineWidth(1.5)
        cg.strokePath()
    }

    NSGraphicsContext.restoreGraphicsState()

    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

let args = CommandLine.arguments
let outputDir = args.count > 1 ? args[1] : "."

renderAndSave(active: false, scale: 1.0, path: "\(outputDir)/stash_menubar.png")
renderAndSave(active: false, scale: 2.0, path: "\(outputDir)/stash_menubar@2x.png")
renderAndSave(active: false, scale: 3.0, path: "\(outputDir)/stash_menubar@3x.png")
renderAndSave(active: true, scale: 1.0, path: "\(outputDir)/stash_menubar_active.png")
renderAndSave(active: true, scale: 2.0, path: "\(outputDir)/stash_menubar_active@2x.png")
renderAndSave(active: true, scale: 3.0, path: "\(outputDir)/stash_menubar_active@3x.png")
