//
//  ProfileController.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Foundation
import Vapor

/// Handles profile-related API routes.
struct ProfileController: RouteCollection, Sendable {
  /// Registers profile routes under the `/profile` path.
  ///
  /// The current route set exposes `GET /profile`, which returns the profile
  /// information for the authenticated user.
  func boot(routes: any RoutesBuilder) throws {
    let profile = routes.grouped("profile")
    profile.get(use: getProfile)
  }
  
  /// Returns the profile for the authenticated user.
  ///
  /// The user is resolved from Vapor's authentication storage, which is populated
  /// earlier by authentication middleware. If no user is authenticated, Vapor
  /// throws an unauthorized error. When a user is available, the database model is
  /// mapped into `ProfileResponse` so the API exposes only profile fields.
  func getProfile(req: Request) async throws -> ProfileResponse {
    let user = try req.auth.require(User.self)
    
    return ProfileResponse(
      id: try user.requireID(),
      email: user.email,
      displayName: user.displayName,
      avatarURL: user.avatarURL
    )
  }
}
