//
//  File.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 11/04/2026.
//

import Foundation
import Fluent
import Vapor

/// Represents an application user persisted in the `users` table.
final class User: Model, Content, @unchecked Sendable {
  /// The database schema (table name) used by Fluent for this model.
  static let schema = "users"
  
  /// The unique identifier assigned by the database.
  @ID(key: .id)
  var id: UUID?
  
  /// The user's email address used for identification and login.
  @Field(key: "email")
  var email: String
  
  /// A secure hash of the user's password.
  @Field(key: "password_hash")
  var passwordHash: String
  
  @Field(key: "display_name")
  var displayName: String?
  
  @Field(key: "avatar_url")
  var avatarURL: String?
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  
  /// Creates an empty `User` instance required by Fluent.
  init() { }
  
  /// Creates a `User` with the provided values.
  /// - Parameters:
  ///   - id: Optional identifier. Usually `nil` before persistence.
  ///   - email: The user's email address.
  ///   - passwordHash: The hashed password value.
  init(id: UUID? = nil, email: String, passwordHash: String) {
    self.id = id
    self.email = email
    self.passwordHash = passwordHash
  }
}

extension User: Authenticatable {
  
}
