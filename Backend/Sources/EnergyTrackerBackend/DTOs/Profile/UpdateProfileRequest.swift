//
//  UpdateProfileRequest.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 27/06/2026.
//

import Foundation
import Vapor

/// Request body used to update the authenticated user's profile.
///
/// All fields are optional so clients can update only the profile values they
/// want to change.
struct UpdateProfileRequest: Content {
  /// User-facing display name shown in the profile.
  let displayName: String?
}

extension UpdateProfileRequest: Validatable {
  /// Defines validation rules for profile update payloads.
  ///
  /// `displayName` may be omitted, but when present it must be non-empty and no
  /// longer than 64 characters.
  static func validations(_ validations: inout Validations) {
    validations.add(
      "displayName",
      as: String.self,
      is: !.empty && .count(...64),
      required: false
    )
  }
}
