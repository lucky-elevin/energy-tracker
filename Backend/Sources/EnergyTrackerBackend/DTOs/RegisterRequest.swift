//
//  RegisterRequest.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 17/05/2026.
//

import Foundation
import Vapor

/// Payload used to register a new user account.
struct RegisterRequest: Content {
    /// User's email address used as the account identifier.
    let email: String

    /// Plain-text password provided during registration.
    let password: String
}

extension RegisterRequest: Validatable {
  static func validations(_ validations: inout Vapor.Validations) {
    let passwordLimit = 8...64
    validations.add("email", as: String.self, is: .email)
    validations.add("password", as: String.self, is: .count(passwordLimit))
  } 
}
