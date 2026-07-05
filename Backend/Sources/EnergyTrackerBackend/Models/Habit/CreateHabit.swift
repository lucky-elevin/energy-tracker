//
//  CreateHabit.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 05/07/2026.
//

import Foundation
import Fluent

/// Creates the database schema for persisted habits.
struct CreateHabit: AsyncMigration {
  /// Creates the `habits` table and its relationship to users.
  ///
  /// Each habit belongs to a user through `user_id`. The foreign key cascades on
  /// delete so a user's habits are removed automatically when the user is
  /// deleted. New habits default to active unless explicitly stored otherwise.
  func prepare(on database: any Database) async throws {
    try await database.schema(Habit.schema)
      .id()
      .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
      .field("title", .string, .required)
      .field("description", .string)
      .field("kind", .string, .required)
      .field("due_date", .datetime)
      .field("is_active", .bool, .required, .sql(.default(true)))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  /// Drops the `habits` table when the migration is reverted.
  func revert(on database: any Database) async throws {
    try await database.schema(Habit.schema).delete()
  }
}
