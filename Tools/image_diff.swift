#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct DiffResult {
    let width: Int
    let height: Int
    let changedPixels: Int
    let totalPixels: Int
    let averageDelta: Double
    let maxDelta: Int

    var changedPercent: Double {
        totalPixels > 0 ? (Double(changedPixels) / Double(totalPixels)) * 100.0 : 0.0
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func loadImage(_ path: String) -> CGImage {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fail("Unable to read image: \(path)")
    }
    return image
}

func rgbaPixels(from image: CGImage, width: Int, height: Int) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fail("Unable to allocate bitmap context")
    }
    context.interpolationQuality = .medium
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return pixels
}

func writePNG(_ pixels: [UInt8], width: Int, height: Int, path: String) {
    var mutablePixels = pixels
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: &mutablePixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = context.makeImage() else {
        fail("Unable to create diff image")
    }

    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fail("Unable to create diff destination: \(path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fail("Unable to write diff image: \(path)")
    }
}

let args = CommandLine.arguments
guard args.count == 4 || args.count == 5 else {
    fail("Usage: Tools/image_diff.swift <baseline.png> <current.png> <diff.png> [threshold]")
}

let baselinePath = args[1]
let currentPath = args[2]
let diffPath = args[3]
let threshold = args.count == 5 ? max(Int(args[4]) ?? 10, 0) : 10

let baseline = loadImage(baselinePath)
let current = loadImage(currentPath)
let width = min(baseline.width, current.width)
let height = min(baseline.height, current.height)
guard width > 0, height > 0 else {
    fail("Images have no comparable pixel area")
}

let baselinePixels = rgbaPixels(from: baseline, width: width, height: height)
let currentPixels = rgbaPixels(from: current, width: width, height: height)
var diffPixels = [UInt8](repeating: 0, count: width * height * 4)
var changedPixels = 0
var totalDelta = 0
var maxDelta = 0

for index in stride(from: 0, to: baselinePixels.count, by: 4) {
    let dr = abs(Int(baselinePixels[index]) - Int(currentPixels[index]))
    let dg = abs(Int(baselinePixels[index + 1]) - Int(currentPixels[index + 1]))
    let db = abs(Int(baselinePixels[index + 2]) - Int(currentPixels[index + 2]))
    let delta = max(dr, max(dg, db))
    totalDelta += delta
    maxDelta = max(maxDelta, delta)

    if delta > threshold {
        changedPixels += 1
        diffPixels[index] = 255
        diffPixels[index + 1] = UInt8(max(40, currentPixels[index + 1] / 3))
        diffPixels[index + 2] = UInt8(max(40, currentPixels[index + 2] / 3))
        diffPixels[index + 3] = 255
    } else {
        diffPixels[index] = currentPixels[index] / 4
        diffPixels[index + 1] = currentPixels[index + 1] / 4
        diffPixels[index + 2] = currentPixels[index + 2] / 4
        diffPixels[index + 3] = 255
    }
}

writePNG(diffPixels, width: width, height: height, path: diffPath)

let totalPixels = width * height
let averageDelta = totalPixels > 0 ? Double(totalDelta) / Double(totalPixels) : 0.0
print(String(format: "pixels=%dx%d changed=%d/%d changedPercent=%.4f averageDelta=%.4f maxDelta=%d threshold=%d",
             width,
             height,
             changedPixels,
             totalPixels,
             (Double(changedPixels) / Double(totalPixels)) * 100.0,
             averageDelta,
             maxDelta,
             threshold))
