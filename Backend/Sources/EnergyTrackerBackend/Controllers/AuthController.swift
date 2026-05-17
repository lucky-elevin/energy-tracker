//
//  AuthController.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 17/05/2026.
//

import Foundation
import Vapor
import Fluent

/// Handles authentication-related HTTP routes.
struct AuthController: RouteCollection {
  /// Registers controller routes under the `/auth` path.
  /// - Parameter routes: Root route builder provided by Vapor.
  func boot(routes: any RoutesBuilder) throws {
    let auth = routes.grouped("auth")
    auth.post("register", use: register)
  }
  
  /// Creates a new user account from registration payload data.
  ///
  /// This endpoint performs the following steps:
  /// 1. Decodes `RegisterRequest` from the incoming HTTP body.
  /// 2. Checks whether a user with the same email already exists.
  /// 3. Returns `409 Conflict` if the email is already registered.
  /// 4. Hashes the plain-text password with BCrypt.
  /// 5. Persists a new `User` row in the database.
  /// 6. Returns `RegisterResponse` containing the created user's id and email.
  ///
  /// - Parameter req: The current HTTP request containing JSON payload and database context.
  /// - Returns: A `RegisterResponse` with public data of the newly created user.
  /// - Throws: `Abort(.conflict)` when a user with the same email already exists,
  ///   plus any decoding, hashing, or database persistence errors.
  @Sendable
  func register(req: Request) async throws -> RegisterResponse {
    try RegisterRequest.validate(content: req)
    // Parse and validate request body as a registration payload.
    let payload = try req.content.decode(RegisterRequest.self)
    // Enforce unique email registration.
    let existingUser = try await User.query(on: req.db)
      .filter(\.$email == payload.email)
      .first()
    
    if existingUser != nil {
      throw Abort(.conflict, reason: "User already exists")
    }
    
    // Never store plain-text passwords.
    let passwordHash = try Bcrypt.hash(payload.password)
    let user = User(email: payload.email, passwordHash: passwordHash)
    try await user.save(on: req.db)
    
    return RegisterResponse(id: user.id, email: user.email)
  }
}
