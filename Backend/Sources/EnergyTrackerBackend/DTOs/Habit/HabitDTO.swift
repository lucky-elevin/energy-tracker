//
//  HabitDTO.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 05/07/2026.
//

import Foundation
import Vapor

/// Request body used to create a habit for the authenticated user.
struct CreateHabitRequest: Content {
  /// Short user-facing name of the habit.
  let title: String

  /// Optional longer description with details about the habit.
  let description: String?

  /// Optional habit kind. The controller can default this when omitted.
  let kind: HabitKind?

  /// Optional date when the habit should be completed or reviewed.
  let dueDate: Date?
}

/// Request body used to update an existing habit.
///
/// All fields are optional so clients can update only the values that changed.
struct UpdateHabitRequest: Content {
  /// New user-facing name of the habit.
  let title: String?

  /// New longer description, or `nil` when omitted by the request.
  let description: String?

  /// New habit kind, or `nil` when the kind should remain unchanged.
  let kind: HabitKind?

  /// New completion or review date, or `nil` when omitted by the request.
  let dueDate: Date?
}

/// Response body returned for habit API endpoints.
struct HabitResponse: Content {
    /// Unique identifier of the habit.
    let id: UUID
  
    /// Short user-facing name of the habit.
    let title: String

    /// Optional longer description with details about the habit.
    let description: String?

    /// Determines how habit progress is recorded and interpreted.
    let kind: HabitKind

    /// Optional date when the habit should be completed or reviewed.
    let dueDate: Date?

    /// Indicates whether the habit is currently active.
    let isActive: Bool

    /// Timestamp when the habit was first created.
    let createdAt: Date?

    /// Timestamp when the habit was last updated.
    let updatedAt: Date?
}

extension HabitResponse {
    /// Creates a response DTO from a persisted `Habit` model.
    init(habit: Habit) throws {
        self.id = try habit.requireID()
        self.title = habit.title
        self.description = habit.description
        self.kind = habit.kind
        self.dueDate = habit.dueDate
        self.isActive = habit.isActive
        self.createdAt = habit.createdAt
        self.updatedAt = habit.updatedAt
    }
}
