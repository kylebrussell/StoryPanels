import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.provider) private var providerRaw = ImageProviderID.google.rawValue
    @AppStorage(SettingsKeys.googleModelName) private var googleModelName = SettingsStore.googleModelName
    @AppStorage(SettingsKeys.googleImageSize) private var googleImageSizeRaw = SettingsStore.googleImageSize.rawValue
    @AppStorage(SettingsKeys.googleAspectRatio) private var googleAspectRatioRaw = SettingsStore.googleAspectRatio.rawValue
    @AppStorage(SettingsKeys.openAIModelName) private var openAIModelName = SettingsStore.openAIModelName

    @State private var googleApiKey: String = ""
    @State private var openAIApiKey: String = ""
    @State private var testStatus: String?
    @State private var isTesting: Bool = false
    @Environment(\.dismiss) private var dismiss

    private let keychain = KeychainStore()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Image Provider")) {
                    Picker("Provider", selection: $providerRaw) {
                        ForEach(ImageProviderID.allCases) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                }

                if selectedProvider == .google {
                    Section(header: Text("Google (Nano Banana Pro)")) {
                        SecureField("Google API key", text: $googleApiKey)
                        TextField("Model name", text: $googleModelName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Picker("Resolution", selection: $googleImageSizeRaw) {
                            ForEach(ImageGenerationSize.allCases) { size in
                                Text(size.rawValue).tag(size.rawValue)
                            }
                        }

                        Picker("Aspect Ratio", selection: $googleAspectRatioRaw) {
                            ForEach(ImageAspectRatio.allCases) { ratio in
                                Text(ratio.rawValue).tag(ratio.rawValue)
                            }
                        }
                    }
                }

                if selectedProvider == .openai {
                    Section(header: Text("OpenAI")) {
                        SecureField("OpenAI API key", text: $openAIApiKey)
                        TextField("Model name", text: $openAIModelName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Section {
                    Button {
                        Task { await runProviderTest() }
                    } label: {
                        if isTesting {
                            Label("Testing...", systemImage: "clock")
                        } else {
                            Label("Test API Key", systemImage: "checkmark.seal")
                        }
                    }
                    .disabled(isTesting)

                    if let testStatus {
                        Text(testStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("About")) {
                    Text("Your API keys are stored securely in the Keychain on this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        persistKeys()
                        dismiss()
                    }
                }
            }
            .onAppear {
                googleApiKey = keychain.get(KeychainKeys.googleAPIKey) ?? ""
                openAIApiKey = keychain.get(KeychainKeys.openAIAPIKey) ?? ""
            }
            .scrollContentBackground(.hidden)
            .background(ComicTheme.paperBackground)
        }
    }

    private var selectedProvider: ImageProviderID {
        ImageProviderID(rawValue: providerRaw) ?? .google
    }

    private func persistKeys() {
        if googleApiKey.isEmpty {
            keychain.delete(KeychainKeys.googleAPIKey)
        } else {
            try? keychain.set(googleApiKey, for: KeychainKeys.googleAPIKey)
        }

        if openAIApiKey.isEmpty {
            keychain.delete(KeychainKeys.openAIAPIKey)
        } else {
            try? keychain.set(openAIApiKey, for: KeychainKeys.openAIAPIKey)
        }
    }

    private func runProviderTest() async {
        testStatus = nil
        isTesting = true
        persistKeys()
        do {
            let image = try await ImageGenerationService.shared.generateImage(prompt: "A quick comic test image.", referenceImage: nil)
            await MainActor.run {
                _ = image
                testStatus = "Test succeeded. API key works."
                isTesting = false
            }
        } catch ImageGenerationError.missingAPIKey {
            await MainActor.run {
                testStatus = "Missing API key for the selected provider."
                isTesting = false
            }
        } catch {
            await MainActor.run {
                testStatus = "Test failed. Check key, model, or network."
                isTesting = false
            }
        }
    }
}
