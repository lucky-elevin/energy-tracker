//
//  RegisterResponse.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 17/05/2026.
//

import Foundation
import Vapor

/// Response returned after a successful user registration.
struct RegisterResponse: Content {
    /// Unique identifier assigned to the created user.
    let id: UUID?

    /// Email address of the newly registered user.
    let email: String
}
