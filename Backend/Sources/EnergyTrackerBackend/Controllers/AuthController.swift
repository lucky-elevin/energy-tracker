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
    auth.post("login", use: login)
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
    let passwordHash = try req.password.hash(payload.password)
    let user = User(email: payload.email, passwordHash: passwordHash)
    try await user.save(on: req.db)
    
    return RegisterResponse(id: user.id, email: user.email)
  }
  
  /// Authenticates an existing user and returns login response data.
  ///
  /// This endpoint performs the following steps:
  /// 1. Validates and decodes `LoginRequest` from the request body.
  /// 2. Looks up a user by the provided email.
  /// 3. Returns `401 Unauthorized` when user is not found.
  /// 4. Verifies the provided password against the stored hash.
  /// 5. Returns `401 Unauthorized` when password verification fails.
  /// 6. Builds a short-lived JWT payload and signs it.
  /// 7. Returns `LoginResponse` with user information and access token.
  ///
  /// - Parameter req: The current HTTP request containing JSON payload and app services.
  /// - Returns: `LoginResponse` for the authenticated user.
  /// - Throws: `Abort(.unauthorized)` for invalid credentials, plus validation,
  ///   decoding, database, password verification, and JWT signing errors.
  @Sendable
  func login(req: Request) async throws -> LoginResponse {
    try LoginRequest.validate(content: req)
    // Parse and validate request body as a login payload.
    let payload = try req.content.decode(LoginRequest.self)
    
    let user = try await User.query(on: req.db)
      .filter(\.$email == payload.email)
      .first()

    guard let existingUser = user else {
      throw Abort(.unauthorized, reason: "Invalid email or password")
    }

    let isPasswordValid = try req.password.verify(
      payload.password,
      created: existingUser.passwordHash
    )

    guard isPasswordValid else {
      throw Abort(.unauthorized, reason: "Invalid email or password")
    }

    // Since this is an access token it will live 15 minutes
    let tokenPayload = SessionToken(
      subject: .init(value: try existingUser.requireID().uuidString),
      expiration: .init(value: Date().addingTimeInterval(15 * 60)),
      email: existingUser.email
    )

    let tokenString = try req.jwt.sign(tokenPayload)

    return LoginResponse(
      id: existingUser.id,
      email: existingUser.email,
      accessToken: tokenString
    )
  }
}
