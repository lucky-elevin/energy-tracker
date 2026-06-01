//
//  AuthControllerTests.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 31/05/2026.
//

import Testing
@testable import EnergyTrackerBackend
import VaporTesting
import Fluent
import Vapor

@Suite("Auth Controller Tests", .serialized)
/// Integration tests for registration and login endpoints in `AuthController`.
struct AuthControllerTests {
  /// Creates and migrates an isolated application instance for each test.
  private func setupTestApp() async throws -> Application {
    let app = try await Application.make(.testing)
    try await configure(app)
    
    try await app.autoRevert()
    try await app.autoMigrate()
    return app
  }
  
  @Test("User registration success")
  /// Verifies that a new user can register and receive a valid response payload.
  func testUserRegistrationSuccess() async throws {
    let app = try await setupTestApp()
    defer {
      Task {
        try await app.asyncShutdown()
      }
    }
    let registerPayload = RegisterRequest(
      email: "test@energy.com",
      password: "SecurePassword123"
    )
    
    try await app.test(.POST, "auth/register", beforeRequest: { req in
      try req.content.encode(registerPayload)
    }, afterResponse: { res in
      #expect(res.status == .ok)
      
      let responseData = try res.content.decode(RegisterResponse.self)
      #expect(responseData.email == "test@energy.com")
      #expect(responseData.id != nil)
    })
  }
  
  @Test("User login unauthorized")
  /// Verifies that login fails with `401 Unauthorized` for an unregistered user.
  func testUserLoginUnauthorized() async throws {
    let app = try await setupTestApp()
    
    defer {
      Task {
        try await app.asyncShutdown()
      }
    }
  
    let email = "jedi@energy.com"
    let password = "UseTheForce123"
    
    // 2. Attempt to login without registration
    let loginPayload = LoginRequest(email: email, password: password)
    
    try await app.test(.POST, "auth/login", beforeRequest: { req in
      try req.content.encode(loginPayload)
    }, afterResponse: { res in
      #expect(res.status == .unauthorized)
    })
  }
 
  @Test("User login success")
  /// Verifies that a registered user can log in and receive a non-empty access token.
  func testUserLoginSuccessReturnsToken() async throws {
    let app = try await setupTestApp()
    defer {
      Task {
        try await app.asyncShutdown()
      }
    }
    let email = "jedi@energy.com"
    let password = "UseTheForce123"
    
    // 1. User registration
    let registerPayload = RegisterRequest(
      email: email,
      password: password
    )
    
    try await app.test(.POST, "auth/register", beforeRequest: { req in
      try req.content.encode(registerPayload)
    })
    
    // 2. Attempt to login
    let loginPayload = LoginRequest(email: email, password: password)
    try await app.test(.POST, "auth/login", beforeRequest: { req in
      try req.content.encode(loginPayload)
    }, afterResponse: { res in
      
      #expect(res.status == .ok)
      
      let loginData = try res.content.decode(LoginResponse.self)
      #expect(loginData.email == email)
      #expect(loginData.id != nil)
      #expect(!loginData.accessToken.isEmpty, "The server must return a JWT token")
    })
  }
}
