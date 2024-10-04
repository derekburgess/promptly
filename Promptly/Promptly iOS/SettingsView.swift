//
//  SettingsView.swift - iOS
//  Promptly - Watch Assistant
//

import SwiftUI
import WatchConnectivity

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var useGPT4o: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                Image("promptlyImage")
                   .resizable()
                   .aspectRatio(contentMode: .fit)
                   .frame(width: 40, height: 40)
                
                Text("Welcome to Promptly! The Watch Assistant programmed by OpenAI ChatGPT 4o. Since Apple won't approve an app that requires a private API key without some complicated in-app purchase money grab on their part, the app is distributed by invite only throught TestFlight. The source code will also be published in a public repository so others can reuse/deploy it for themselves.\n\nThe app does require your own OpenAI API key to work. Enter or paste your API key below and it will be shared with your Apple Watch automatically. Apple's WatchConnectivity API can be wonky, and it seems best to not have both settings views open at the same time... The app is set to GPT-3.5 Turbo by default, but can be switched to GPT-4o from the settings view. Enjoy!\n\nCaveats: This app was programmed by AI... It was tested using simulators and a limited number of physical devices...")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                    )
                    .padding([.leading, .trailing])
                    .padding(.bottom, 20)
                
                TextField("OpenAI API Key", text: $apiKey)
                    .padding([.leading, .trailing])
                    .onChange(of: apiKey) {
                        saveSettings()
                        sendSettingsToWatch()
                    }
                    .accessibilityLabel("Enter OpenAI API Key")

                Toggle(isOn: $useGPT4o) {
                    Text("GPT-4o")
                }
                .padding()
                .onChange(of: useGPT4o) {
                    saveSettings()
                    sendSettingsToWatch()
                }
                .accessibilityLabel("Toggle GPT-4o")
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/derekburgess/promptly")!)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding([.leading, .trailing], 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 20)
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

    func sendSettingsToWatch() {
        guard !apiKey.isEmpty else { return }

        let message = ["apiKey": apiKey, "useGPT4o": useGPT4o] as [String : Any]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending settings to watch: \(error.localizedDescription)")
                WCSession.default.transferUserInfo(message)
            })
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }

    func setupConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = PhoneSessionDelegate.shared
            WCSession.default.activate()
        }
    }
}

class PhoneSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionDelegate()

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

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
