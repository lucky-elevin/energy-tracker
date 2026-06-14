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

/// Tests the profile endpoints exposed by `ProfileController`.
///
/// The suite is serialized because the tests use a shared test application setup
/// and database state that should not be exercised concurrently.
@Suite("ProfileControllerTests tests", .serialized)
struct ProfileControllerTests {  
  /// Verifies that an authenticated user can fetch their profile.
  ///
  /// The test registers a user, logs in to obtain a bearer token, and uses that
  /// token to call `GET /profile`. A successful response should contain the
  /// authenticated user's email and identifier while optional profile fields
  /// remain empty for a newly registered account.
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
  
  /// Verifies that `GET /profile` rejects requests without a bearer token.
  ///
  /// The route requires an authenticated user, so a request that does not pass
  /// through `SessionTokenAuthenticator` should fail with `401 Unauthorized`.
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
