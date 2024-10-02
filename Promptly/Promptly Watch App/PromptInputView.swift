//
//  PromptInputView.swift
//  Promptly - Watch Assistant
//

import SwiftUI
import AVFoundation

struct PromptInputView: View {
    @State private var userInput: String = ""
    @State private var responseText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedModel: String = "gpt-3.5-turbo"
    @FocusState private var isTextFieldFocused: Bool
    
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                TextField("Message Assistant", text: $userInput)
                    .padding([.leading, .trailing])
                    .disabled(isLoading)
                    .focused($isTextFieldFocused)

                HStack {
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .disabled(userInput.isEmpty || isLoading)

                    Button(action: {
                        clearFields()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }

                HStack {
                    Button(action: {
                        speakResponse()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .disabled(responseText.isEmpty)
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                }

                Group {
                    if isLoading {
                        ProgressView("Contemplating...")
                    } else {
                        Text(responseText)
                    }
                }
                .padding()
            }
        }
        .background(Color(red: 34/255, green: 0/255, blue: 68/255))
        .onAppear(perform: loadSettings)
    }

    func loadSettings() {
        let useGPT4o = UserDefaults.standard.bool(forKey: "useGPT4o")
        selectedModel = useGPT4o ? "gpt-4o" : "gpt-3.5-turbo"
    }

    func sendMessage() {
        isLoading = true
        responseText = ""

        // Retrieve API Key
        guard let apiKeyData = KeychainHelper.shared.load(key: "openai_api_key"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              !apiKey.isEmpty else {
            responseText = "API Key not set. Please add it to the Settings."
            isLoading = false
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": selectedModel,
            "messages": [
                ["role": "user", "content": userInput]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters) else {
            responseText = "Failed to create request body."
            isLoading = false
            return
        }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.responseText = "Error: \(error.localizedDescription)"
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    self.responseText = "Error: HTTP \(httpResponse.statusCode)"
                    return
                }

                guard let data = data else {
                    self.responseText = "No data received."
                    return
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Full JSON response: \(jsonString)")
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.responseText = content
                    } else {
                        self.responseText = "Invalid response format."
                    }
                } catch {
                    self.responseText = "Failed to parse response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func speakResponse() {
        guard !responseText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: responseText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    func clearFields() {
        userInput = ""
        responseText = ""
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}
