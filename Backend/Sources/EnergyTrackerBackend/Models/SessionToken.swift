//
//  SessionToken.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 30/05/2026.
//
import Foundation
import Vapor
import JWT

/// JWT payload representing an authenticated user session.
struct SessionToken: JWTPayload, Authenticatable {
    /// Unique subject identifier of the token (typically a user id).
    var subject: SubjectClaim

    /// Expiration timestamp after which the token is no longer valid.
    var expiration: ExpirationClaim

    /// Email associated with the authenticated user session.
    var email: String

    /// Validates payload claims when the token is decoded.
    ///
    /// - Parameter signer: JWT signer used by the verification pipeline.
    /// - Throws: An error if the expiration claim indicates an expired token.
    func verify(using signer: JWTKit.JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
