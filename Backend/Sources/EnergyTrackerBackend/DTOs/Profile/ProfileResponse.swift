//
//  ProfileResponse.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Foundation
import Vapor

struct AvatarResponse: Content {
  let smallURL: String
  let largeURL: String
}

struct ProfileResponse: Content {
  
  let id: UUID
  
  let email: String
  
  let displayName: String?
  
  let avatar: AvatarResponse?
}


/// Response body returned after updating the authenticated user's profile.
///
/// The response includes the stable account identity fields together with the
/// profile values after the update has been applied
extension ProfileResponse {
  init(user: User) throws {
    let avatar: AvatarResponse?

    if let smallURL = user.avatarSmallURL,
       let largeURL = user.avatarLargeURL
    {
      avatar = .init(smallURL: smallURL, largeURL: largeURL)
    } else {
      avatar = nil
    }

    self.init(
      id: try user.requireID(),
      email: user.email,
      displayName: user.displayName,
      avatar: avatar
    )
  }
}
