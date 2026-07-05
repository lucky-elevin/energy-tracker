//
//  AvatarProcessorKey.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 28/06/2026.
//

import Foundation
import Vapor

import Vapor

struct AvatarProcessorKey: StorageKey {
  typealias Value = any AvatarProcessing
}

extension Application {
  var avatarProcessor: any AvatarProcessing {
    get {
      guard let processor = storage[AvatarProcessorKey.self] else {
        fatalError("Avatar processor is not configured")
      }
      return processor
    }
    set {
      storage[AvatarProcessorKey.self] = newValue
    }
  }
}
