//
//  AvatarProcessing.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 28/06/2026.
//

import Foundation

public protocol AvatarProcessing: Sendable {
  func process(
    inputPath: String,
    smallOutputPath: String,
    largeOutputPath: String
  ) async throws
}
