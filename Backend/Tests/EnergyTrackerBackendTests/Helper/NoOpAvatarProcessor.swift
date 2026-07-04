//
//  NoOpAvatarProcessor.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 04/07/2026.
//

import Foundation
@testable import EnergyTrackerBackend

struct NoOpAvatarProcessor: AvatarProcessing {
  func process(
    inputPath: String,
    smallOutputPath: String,
    largeOutputPath: String
  ) async throws {
    try FileManager.default.copyItem(atPath: inputPath, toPath: smallOutputPath)
    try FileManager.default.copyItem(atPath: inputPath, toPath: largeOutputPath)
  }
}
