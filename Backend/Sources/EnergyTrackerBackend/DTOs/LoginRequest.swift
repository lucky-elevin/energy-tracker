//
//  LoginRequest.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 24/05/2026.
//

import Foundation
import Vapor

struct LoginRequest: Content {
  let email: String
  let password: String
}

extension LoginRequest: Validatable {
  static func validations(_ validations: inout Vapor.Validations) {
    validations.add("email", as: String.self, is: .email)
    validations.add("password", as: String.self, is: !.empty)
  }
}
