//
//  sec_osx_appApp.swift
//  sec-osx-app
//
//  Created on macOS
//

import SwiftUI

@main
struct sec_osx_appApp: App {
    @StateObject private var securityManager = SecurityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(securityManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

