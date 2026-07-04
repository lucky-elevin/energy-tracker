//
//  SessionTokenAuthenticator.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 13/06/2026.
//

import Foundation
import Vapor
import JWT

/// Authenticates requests using session bearer tokens.
struct SessionTokenAuthenticator: AsyncBearerAuthenticator {
  /// Verifies the bearer token and logs the associated user into the request.
  ///
  /// The token is decoded as a `SessionToken`, whose subject is expected to
  /// contain the user's UUID. If the subject cannot be parsed or the user no
  /// longer exists, the request is left unauthenticated so route middleware can
  /// reject it through the normal authentication flow.
  func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
    let payload = try request.jwt.verify(
      bearer.token,
      as: SessionToken.self
    )

    guard let userID = UUID(uuidString: payload.subject.value),
    let user = try await User.find(userID, on: request.db) else {
      return
    }

    request.auth.login(user)
  }
}
