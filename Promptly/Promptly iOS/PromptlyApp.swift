//
//  PromptlyApp.swift - iOS
//  Promptly
//

import SwiftUI
import WatchConnectivity

@main
struct PromptlyApp: App {
    init() {
            setupConnectivity()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SettingsView()
            }
        }
    }
    
    func setupConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = PhoneSessionDelegate.shared
            session.activate()
        }
    }

}

