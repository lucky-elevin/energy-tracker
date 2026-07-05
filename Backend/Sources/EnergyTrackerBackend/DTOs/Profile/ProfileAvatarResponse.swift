//
//  ProfileAvatarResponse.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 28/06/2026.
//

import Foundation
import Vapor

struct ProfileAvatarResponse: Content {
  let smallURL: String
  let largeURL: String
}
