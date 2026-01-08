import AppKit

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// Background - Disk shape
let path = NSBezierPath(ovalIn: NSRect(x: 100, y: 100, width: size - 200, height: size - 200))
NSColor.systemBlue.setFill()
path.fill()

// NTFS Text
let text = "NTFS" as NSString
let font = NSFont.boldSystemFont(ofSize: 200)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white
]
let textSize = text.size(withAttributes: attributes)
let textRect = NSRect(
    x: (CGFloat(size) - textSize.width) / 2,
    y: (CGFloat(size) - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)
text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

let bitmapRep = NSBitmapImageRep(data: image.tiffRepresentation!)!
let pngData = bitmapRep.representation(using: .png, properties: [:])!

// Save to disk
let currentDirectory = FileManager.default.currentDirectoryPath
let fileURL = URL(fileURLWithPath: currentDirectory).appendingPathComponent("icon.png")
try! pngData.write(to: fileURL)

print("Icon saved to \(fileURL.path)")
