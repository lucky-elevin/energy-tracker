//
//  KaizenApp.swift
//  Kaizen
//
//  Created by Yauheni Levin on 21/04/2026.
//

import SwiftUI
import Firebase

@main
struct KaizenApp: App {
  
  init() {
    FirebaseApp.configure()
  }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
