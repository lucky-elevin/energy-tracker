//
//  ProfileController.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Foundation
import Vapor

/// Handles profile-related API routes.
struct ProfileController: RouteCollection, Sendable {
  /// Registers profile routes under the `/profile` path.
  ///
  /// The current route set exposes `GET /profile`, which returns the profile
  /// information for the authenticated user.
  func boot(routes: any RoutesBuilder) throws {
    let profile = routes.grouped("profile")
    profile.get(use: getProfile)
    profile.patch(use: updateProfile)
    profile.post(use: uploadAvatar)
  }
  
  /// Returns the profile for the authenticated user.
  ///
  /// The user is resolved from Vapor's authentication storage, which is populated
  /// earlier by authentication middleware. If no user is authenticated, Vapor
  /// throws an unauthorized error. When a user is available, the database model is
  /// mapped into `ProfileResponse` so the API exposes only profile fields.
  func getProfile(req: Request) async throws -> ProfileResponse {
    let user = try req.auth.require(User.self)
    let avatar: AvatarResponse?
    
    if let smallURL = user.avatarSmallURL,
       let largeURL = user.avatarLargeURL {
      avatar = .init(smallURL: smallURL, largeURL: largeURL)
    } else {
      avatar = nil
    }
    
    return ProfileResponse(
      id: try user.requireID(),
      email: user.email,
      displayName: user.displayName,
      avatar: avatar
    )
  }
  
  func updateProfile(req: Request) async throws -> ProfileResponse {
    try UpdateProfileRequest.validate(content: req)
    
    let user = try req.auth.require(User.self)
    let payload = try req.content.decode(UpdateProfileRequest.self)
    
    if let displayName = payload.displayName {
      let trimmedDisplayName = displayName
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedDisplayName.isEmpty else {
        throw Abort(.badRequest, reason: "Display name cannot be empty")
      }
      user.displayName = trimmedDisplayName
    }
    try await user.save(on: req.db)
    
    return try ProfileResponse(user: user)
  }
  
  func uploadAvatar(req: Request) async throws -> ProfileResponse {
    let user = try req.auth.require(User.self)
    let payload = try req.content.decode(AvatarUploadRequest.self)
    let maxSize = 5 * 1024 * 1024
    
    guard payload.avatar.data.readableBytes <= maxSize else {
      throw Abort(.payloadTooLarge, reason: "Avatar image is too large")
    }
    
    let supportedFormats = ["image/jpeg", "image/png", "image/webp"]
    
    guard let contentType = payload.avatar.contentType?.serialize(), supportedFormats.contains(contentType) else {
      throw Abort(.badRequest, reason: "Only JPEG, PNG and WebP images are supported")
    }
    
    let userId = try user.requireID()
    let avatarDirectory = req.application.directory.publicDirectory
    + "avatars/\(userId.uuidString)/"
    
    try FileManager.default.createDirectory(
      atPath: avatarDirectory,
      withIntermediateDirectories: true
    )
    
    let originalPath = avatarDirectory + "original_upload"
    let smallPath = avatarDirectory + "small.jpg"
    let largePath = avatarDirectory + "large.jpg"
    
    try await req.fileio.writeFile(payload.avatar.data, at: originalPath)
    
    defer {
      try? FileManager.default.removeItem(
        atPath: originalPath
      )
    }
    
    try await req.application.avatarProcessor.process(
      inputPath: originalPath,
      smallOutputPath: smallPath,
      largeOutputPath: largePath
    )
    
    user.avatarSmallURL = "/avatars/\(userId.uuidString)/small.jpg"
    user.avatarLargeURL = "/avatars/\(userId.uuidString)/large.jpg"
    
    try await user.save(on: req.db)
    return try ProfileResponse(user: user)
  }
  
  private static func runMagick(
    inputPath: String,
    outputPath: String,
    size: Int
  ) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/magick")
    
    process.arguments = [
      inputPath,
      "-auto-orient",
      "-resize", "\(size)x\(size)^",
      "-gravity", "center",
      "-extent", "\(size)x\(size)",
      "-strip",
      "-quality", "85",
      outputPath
    ]
    
    try process.run()
    process.waitUntilExit()
    
    guard process.terminationStatus == 0 else {
      throw Abort(.internalServerError, reason: "Failed to process avatar image")
    }
  }
}
