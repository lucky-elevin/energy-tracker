//
//  LoginResponse.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 24/05/2026.
//

import Foundation
import Vapor

struct LoginResponse: Content {
  let id: UUID?
  let email: String
  let accessToken: String
}
