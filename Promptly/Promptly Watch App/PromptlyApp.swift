//
//  PromptlyApp.swift - WatchOS
//  Promptly - Watch Assistant
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
                PromptInputView()
            }
        }
    }
    
    func setupConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchSessionDelegate.shared
            session.activate()
        }
    }

}
