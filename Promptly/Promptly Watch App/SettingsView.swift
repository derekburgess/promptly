//
//  SettingsView.swift - WatchOS
//  Promptly - Watch Assistant
//

import SwiftUI
import WatchConnectivity

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var useGPT4o: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack {
            Text("Tip: Use the companion iOS app to paste your API key.")
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                )
                .padding([.leading, .trailing])
                .padding(.bottom, 10)
                .padding(.top, 10)
                .font(.system(size: 12))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            TextField("API Key", text: $apiKey)
                .padding([.leading, .trailing])
                .focused($isTextFieldFocused)
                .onChange(of: apiKey) {
                    saveSettings()
                    sendSettingsToPhone()
                }

            Toggle(isOn: $useGPT4o) {
                Text("GPT-4o")
            }
            .padding()
            .onChange(of: useGPT4o) {
                saveSettings()
                sendSettingsToPhone()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 34/255, green: 0/255, blue: 68/255))
        .onAppear {
            loadSettings()
            setupConnectivity()
        }
    }

    func saveSettings() {
        guard !apiKey.isEmpty else { return }
        if let data = apiKey.data(using: .utf8) {
            KeychainHelper.shared.save(key: "openai_api_key", data: data)
        }
        UserDefaults.standard.set(useGPT4o, forKey: "useGPT4o")
    }

    func loadSettings() {
        if let data = KeychainHelper.shared.load(key: "openai_api_key"),
           let key = String(data: data, encoding: .utf8) {
            apiKey = key
        }
        useGPT4o = UserDefaults.standard.bool(forKey: "useGPT4o")
    }

    func sendSettingsToPhone() {
        guard !apiKey.isEmpty else { return }
        if WCSession.default.isReachable {
            let message = ["apiKey": apiKey, "useGPT4o": useGPT4o] as [String : Any]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending settings to phone: \(error.localizedDescription)")
            })
        }
    }

    func setupConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = WatchSessionDelegate.shared
            WCSession.default.activate()
        }
    }
}

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let newApiKey = message["apiKey"] as? String {
                if let data = newApiKey.data(using: .utf8) {
                    KeychainHelper.shared.save(key: "openai_api_key", data: data)
                }
            }
            if let newUseGPT4o = message["useGPT4o"] as? Bool {
                UserDefaults.standard.set(newUseGPT4o, forKey: "useGPT4o")
            }
        }
    }
}
