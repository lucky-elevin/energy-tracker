//
//  ProfileControllerTests.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Foundation
@testable import EnergyTrackerBackend
import VaporTesting
import Fluent
import Vapor
import Testing

@Suite("ProfileControllerTests tests", .serialized)
struct ProfileControllerTests {
  /// Creates and migrates an isolated application instance for each test.
  private func withTestApp(
    _ body: (Application) async throws -> Void
  ) async throws {
    let app = try await Application.make(.testing)
    
    do {
      try await configure(app)
      try await app.autoRevert()
      try await app.autoMigrate()
      
      try await body(app)
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    
    try await app.asyncShutdown()
  }
  
  @Test("User profile success")
  func testUserProfileSuccess() async throws {
    try await withTestApp { app in
      let email = "profile@energy.com"
      let password = "SecurePassword123"

      let registerPayload = RegisterRequest(email: email, password: password)

      try await app.test(.POST, "auth/register") { req in
        try req.content.encode(registerPayload)
      } afterResponse: { req in
        #expect(req.status == .ok)
      }

      let loginPayload = LoginRequest(
            email: email,
            password: password
          )

          var accessToken = ""

          try await app.test(
            .POST,
            "auth/login",
            beforeRequest: { req in
              try req.content.encode(loginPayload)
            },
            afterResponse: { res in
              #expect(res.status == .ok)
              let loginResponse = try res.content.decode(LoginResponse.self)
              accessToken = loginResponse.accessToken
              #expect(!accessToken.isEmpty)
            }
          )

          try await app.test(
            .GET,
            "profile",
            beforeRequest: { req in
              req.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
            },
            afterResponse: { res in
              #expect(res.status == .ok)
              let profileResponse = try res.content.decode(ProfileResponse.self)
              #expect(profileResponse.email == email)
              #expect(!profileResponse.id.uuidString.isEmpty)
              #expect(profileResponse.displayName == nil)
              #expect(profileResponse.avatarURL == nil)
            }
        )
    }
  }
  
  @Test("User profile unauthorized without token")
  func testUserProfileUnauthorizedWithoutToken() async throws {
    try await withTestApp { app in
      try await app.test(
        .GET,
        "profile",
        afterResponse: { res in
          #expect(res.status == .unauthorized)
        }
      )
    }
  }
}
