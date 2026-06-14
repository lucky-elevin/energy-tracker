//
//  ProfileResponse.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Foundation
import Vapor

struct ProfileResponse: Content {

    let id: UUID

    let email: String

    let displayName: String?

    let avatarURL: String?

}
