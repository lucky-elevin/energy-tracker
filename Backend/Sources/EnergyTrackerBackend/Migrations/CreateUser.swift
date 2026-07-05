//
//  File.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 11/04/2026.
//

import Foundation
import Fluent

struct CreateUser: Migration {
  func prepare(on database: any Database) -> EventLoopFuture<Void> {
    database.schema("users")
      .id()
      .field("email", .string, .required)
      .field("password_hash", .string, .required)
      .field("display_name", .string)
      .field("created_at", .datetime)
      .field("avatar_small_url", .string)
      .field("avatar_large_url", .string)
      .unique(on: "email")
      .create()
  }
  
  func revert(on database: any Database) -> EventLoopFuture<Void> {
    database.schema("users").delete()
  }
}
