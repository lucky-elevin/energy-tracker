//
//  ImageMagickAvatarProcessor.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 28/06/2026.
//

import Foundation
import Vapor

import Foundation
import Vapor

struct ImageMagickAvatarProcessor: AvatarProcessing, Sendable {
  private let magickPath: String

  init(magickPath: String? = nil) throws {
    self.magickPath = try magickPath ?? Self.resolveMagickPath()
  }

  func process(
    inputPath: String,
    smallOutputPath: String,
    largeOutputPath: String
  ) async throws {
    try await runMagick(inputPath: inputPath, outputPath: smallOutputPath, size: 128)
    try await runMagick(inputPath: inputPath, outputPath: largeOutputPath, size: 1024)
  }

  private static func resolveMagickPath() throws -> String {
    if let path = Environment.get("MAGICK_PATH") {
      guard FileManager.default.isExecutableFile(atPath: path) else {
        throw Abort(.internalServerError, reason: "MAGICK_PATH is not executable")
      }
      return path
    }

    let candidates = [
      "/opt/homebrew/bin/magick",
      "/usr/local/bin/magick",
      "/usr/bin/magick"
    ]

    for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
      return path
    }

    throw Abort(.internalServerError, reason: "ImageMagick executable was not found")
  }

  private func runMagick(
    inputPath: String,
    outputPath: String,
    size: Int
  ) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: magickPath)
    process.arguments = [
      inputPath,
      "-auto-orient",
      "-resize", "\(size)x\(size)^",
      "-gravity", "center",
      "-extent", "\(size)x\(size)",
      "-strip",
      "-quality", "85",
      outputPath
    ]

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw Abort(.internalServerError, reason: "Failed to process avatar image")
    }
  }
}
