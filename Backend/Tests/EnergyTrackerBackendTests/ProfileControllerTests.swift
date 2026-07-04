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
  /// Registers a user and returns a bearer token for authenticated profile requests.
  ///
  /// Profile routes are protected by `SessionTokenAuthenticator`, so tests that
  /// exercise controller behavior need to create a real user session first.
  private func registerAndLogin(
    app: Application,
    email: String = "profile@energy.com",
    password: String = "SecurePassword123"
  ) async throws -> String {
    let registerPayload = RegisterRequest(email: email, password: password)

    try await app.test(.POST, "auth/register") { req in
      try req.content.encode(registerPayload)
    } afterResponse: { res in
      #expect(res.status == .ok)
    }

    let loginPayload = LoginRequest(email: email, password: password)
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

    return accessToken
  }
  
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
      let accessToken = try await registerAndLogin(app: app, email: email)

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
          #expect(profileResponse.avatar?.smallURL == nil)
          #expect(profileResponse.avatar?.largeURL == nil)
        }
      )
    }
  }
  
  /// Verifies that an authenticated user can update their display name.
  ///
  /// The controller trims surrounding whitespace before saving the profile, so
  /// the response should contain the normalized display name.
  @Test("User profile update success")
  func testUserProfileUpdateSuccess() async throws {
    try await withTestApp { app in
      let accessToken = try await registerAndLogin(
        app: app,
        email: "profile-update@energy.com"
      )
      let updatePayload = UpdateProfileRequest(displayName: "  Energy User  ")

      try await app.test(
        .PATCH,
        "profile",
        beforeRequest: { req in
          req.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
          try req.content.encode(updatePayload)
        },
        afterResponse: { res in
          #expect(res.status == .ok)
          let profileResponse = try res.content.decode(ProfileResponse.self)
          #expect(profileResponse.displayName == "Energy User")
        }
      )
    }
  }
  
  /// Verifies that blank display names are rejected after trimming.
  ///
  /// The validation layer allows non-empty strings, while the controller performs
  /// the additional whitespace-only check before saving.
  @Test("User profile update rejects blank display name")
  func testUserProfileUpdateRejectsBlankDisplayName() async throws {
    try await withTestApp { app in
      let accessToken = try await registerAndLogin(
        app: app,
        email: "profile-blank@energy.com"
      )
      let updatePayload = UpdateProfileRequest(displayName: "   ")

      try await app.test(
        .PATCH,
        "profile",
        beforeRequest: { req in
          req.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
          try req.content.encode(updatePayload)
        },
        afterResponse: { res in
          #expect(res.status == .badRequest)
        }
      )
    }
  }
  
  /// Verifies that `PATCH /profile` rejects requests without a bearer token.
  ///
  /// The protected route group should stop unauthenticated update requests before
  /// the controller mutates any profile data.
  @Test("User profile update unauthorized without token")
  func testUserProfileUpdateUnauthorizedWithoutToken() async throws {
    try await withTestApp { app in
      let updatePayload = UpdateProfileRequest(displayName: "Energy User")

      try await app.test(
        .PATCH,
        "profile",
        beforeRequest: { req in
          try req.content.encode(updatePayload)
        },
        afterResponse: { res in
          #expect(res.status == .unauthorized)
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
