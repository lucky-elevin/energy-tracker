//
//  File.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 05/07/2026.
//

import Foundation

/// Describes how a habit's progress should be recorded.
enum HabitKind: String, Codable {
    /// A habit that is either completed or not completed.
    case boolean

    /// A habit tracked with a numeric value, such as minutes, count, or amount.
    case numeric
}
