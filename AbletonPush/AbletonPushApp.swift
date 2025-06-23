//
//  AbletonPushApp.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI
import SwiftData

@main
struct AbletonPushApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SoundPadEntity.self)
    }
}
