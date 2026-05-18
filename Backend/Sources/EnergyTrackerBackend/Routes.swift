//
//  Routes.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 18/05/2026.
//

import Foundation
import Vapor

public func routes(_ app: Application) throws {
  app.get{ req in
    return  "EnergyTracker is Running"
  }
  
  app.get("health") { req in
    return ["status": "up"]
  }
  
  try app.register(collection: AuthController())
}
