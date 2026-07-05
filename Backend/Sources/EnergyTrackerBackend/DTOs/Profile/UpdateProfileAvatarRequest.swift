//
//  File.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 28/06/2026.
//

import Foundation
import Vapor

struct AvatarUploadRequest: Content {
  let avatar: File
}
