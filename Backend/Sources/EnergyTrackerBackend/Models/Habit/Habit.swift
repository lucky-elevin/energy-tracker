//
//  Habit.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 05/07/2026.
//

import Fluent
import Foundation

/// Represents a trackable habit owned by a user.
///
/// Habits can be simple boolean tasks, such as marking an action complete, or
/// numeric habits where the client records a measured value.
final class Habit: Model, @unchecked Sendable {
    /// The database schema used by Fluent for habit records.
    static let schema = "habits"

    /// The unique identifier assigned by the database.
    @ID(key: .id)
    var id: UUID?

    /// The user that owns this habit.
    @Parent(key: "user_id")
    var user: User

    /// Short user-facing name of the habit.
    @Field(key: "title")
    var title: String

    /// Optional longer description with details about the habit.
    @OptionalField(key: "description")
    var description: String?

    /// Determines how habit progress is recorded and interpreted.
    @Field(key: "kind")
    var kind: HabitKind

    /// Optional date when the habit is expected to be completed or reviewed.
    @OptionalField(key: "due_date")
    var dueDate: Date?

    /// Indicates whether the habit is currently active.
    @Field(key: "is_active")
    var isActive: Bool

    /// Timestamp set when the habit is first created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// Timestamp updated whenever the habit record changes.
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    /// Creates an empty `Habit` instance required by Fluent.
    init() {}

    /// Creates a habit with the provided values.
    ///
    /// - Parameters:
    ///   - id: Optional identifier. Usually `nil` before persistence.
    ///   - userID: Identifier of the user that owns the habit.
    ///   - title: Short user-facing name of the habit.
    ///   - description: Optional longer description.
    ///   - kind: The way progress should be recorded for this habit.
    ///   - dueDate: Optional completion or review date.
    ///   - isActive: Whether the habit is currently active.
    init(
        id: UUID? = nil,
        userID: User.IDValue,
        title: String,
        description: String? = nil,
        kind: HabitKind = .boolean,
        dueDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.$user.id = userID
        self.title = title
        self.description = description
        self.kind = kind
        self.dueDate = dueDate
        self.isActive = isActive
    }
}
