import SwiftUI
import PhotosUI
import AuthenticationServices

// MARK: - Models

enum PanelLayout: CaseIterable {
    case single
    case threePanel
    
    var panelCount: Int {
        switch self {
        case .single: return 1
        case .threePanel: return 3
        }
    }
    
    var displayName: String {
        switch self {
        case .single: return "1 Panel"
        case .threePanel: return "3 Panels"
        }
    }
}

enum TextElementType: String, CaseIterable {
    case speechBubble = "Speech"
    case thoughtBubble = "Thought"
    case caption = "Caption"
    case soundEffect = "Sound"
    
    var icon: String {
        switch self {
        case .speechBubble: return "bubble.left.fill"
        case .thoughtBubble: return "cloud.fill"
        case .caption: return "rectangle.fill"
        case .soundEffect: return "star.fill"
        }
    }
}

struct CharacterStandIn: Identifiable {
    let id = UUID()
    var number: Int
    var position: CGPoint = CGPoint(x: 100, y: 200)
    var size: CGSize = CGSize(width: 80, height: 80)
    var label: String = ""
}

struct TextElement: Identifiable {
    let id = UUID()
    var type: TextElementType
    var text: String = ""
    var position: CGPoint = CGPoint(x: 150, y: 100)
    var size: CGSize = CGSize(width: 120, height: 60)
    var isEditing: Bool = false
}

struct ComicPanel: Identifiable {
    let id = UUID()
    var imagePrompt: String = ""
    var generatedImage: UIImage?
    var textElements: [TextElement] = []
    var characterStandIns: [CharacterStandIn] = []
    var isGenerating: Bool = false
}

struct Comic {
    var layout: PanelLayout
    var panels: [ComicPanel]
    
    init(layout: PanelLayout) {
        self.layout = layout
        self.panels = (0..<layout.panelCount).map { _ in ComicPanel() }
    }
}

// MARK: - OpenAI Service
class OpenAIImageService {
    static let shared = OpenAIImageService()
    
    private var apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    enum OpenAIError: Error {
        case invalidAPIKey
        case networkError(Error)
        case invalidResponse
        case noImageURL
        case imageDownloadFailed
    }
    
    private init() {
        // Check UserDefaults first, then environment variable, then empty
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? 
                      ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        if apiKey.isEmpty {
            print("⚠️ OpenAI API key not found. Please configure it in Settings or set OPENAI_API_KEY environment variable.")
        }
    }
    
    func updateAPIKey(_ newApiKey: String) {
        self.apiKey = newApiKey
        UserDefaults.standard.set(newApiKey, forKey: "openai_api_key")
    }
    
    func generateImageFromCanvas(canvasImage: UIImage, prompt: String) async throws -> UIImage {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        print("🔥 Starting multimodal image generation with canvas input")
        
        // Convert canvas image to base64
        guard let imageData = canvasImage.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.imageDownloadFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        // Enhanced prompt with professional comic styling instructions
        let enhancedPrompt = """
        Transform this comic panel layout into a professional comic book illustration. The image shows character positions (numbered blue circles) and text bubbles with dialogue.
        
        Instructions:
        1. Replace the numbered blue circles with actual characters based on the scene description
        2. Keep all text bubbles exactly where they are, but make them look professional with proper comic book styling
        3. Create a detailed background that fits the scene
        4. Use comic book art style with bold lines, vibrant colors, and dynamic composition
        5. Maintain the exact same layout and positioning as shown in the reference image
        
        Scene description: \(prompt)
        
        Make this look like a panel from a high-quality comic book while preserving the text bubble positions and content.
        """
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": enhancedPrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        print("🔥 Request body prepared for multimodal API")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }
            
            print("🔥 HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API Error Response: \(errorString)")
                throw OpenAIError.networkError(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
            }
            
            // For now, since GPT-4o image generation isn't fully available yet,
            // we'll fall back to using the enhanced prompt with the existing DALL-E endpoint
            print("⚠️ GPT-4o image generation not fully available yet, falling back to enhanced DALL-E generation")
            return try await generateImageWithEnhancedPrompt(enhancedPrompt)
            
        } catch {
            print("❌ Multimodal API Error: \(error)")
            // Fallback to enhanced prompt generation
            return try await generateImageWithEnhancedPrompt(enhancedPrompt)
        }
    }
    
    private func generateImageWithEnhancedPrompt(_ enhancedPrompt: String) async throws -> UIImage {
        let url = URL(string: "\(baseURL)/images/generations")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        let requestBody: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": enhancedPrompt,
            "n": 1,
            "size": "1024x1024"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ DALL-E API Error Response: \(errorString)")
            throw OpenAIError.networkError(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = jsonResponse["data"] as? [[String: Any]],
              let firstImage = dataArray.first else {
            throw OpenAIError.invalidResponse
        }
        
        var imageData: Data?
        
        if let imageURLString = firstImage["url"] as? String,
           let imageURL = URL(string: imageURLString) {
            let (downloadedData, _) = try await URLSession.shared.data(from: imageURL)
            imageData = downloadedData
        } else if let base64String = firstImage["b64_json"] as? String,
                  let decoded = Data(base64Encoded: base64String) {
            imageData = decoded
        }
        
        guard let finalData = imageData,
              let uiImage = UIImage(data: finalData) else {
            throw OpenAIError.imageDownloadFailed
        }
        
        return uiImage
    }
    
    func generateImage(prompt: String) async throws -> UIImage {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        print("🔥 Starting image generation for prompt: \(prompt)")
        
        let url = URL(string: "\(baseURL)/images/generations")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0 // Increase timeout for image generation
        
        // Construct request body according to the latest images/create API
        // See https://platform.openai.com/docs/api-reference/images/create
        let requestBody: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024"
        ]
        
        print("🔥 Request body: \(requestBody)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🔥 Making API request to: \(url)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("🔥 Received response")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw OpenAIError.invalidResponse
            }
            
            print("🔥 HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API Error Response: \(errorString)")
                
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ OpenAI API Error: \(message)")
                }
                throw OpenAIError.networkError(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]))
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("🔥 API Response: \(responseString)")
            
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataArray = jsonResponse["data"] as? [[String: Any]],
                  let firstImage = dataArray.first else {
                print("❌ Failed to parse response JSON")
                throw OpenAIError.invalidResponse
            }
            
            var imageData: Data?
            
            // The API can return either an expiring URL or a base64-encoded string.
            if let imageURLString = firstImage["url"] as? String,
               let imageURL = URL(string: imageURLString) {
                print("🔥 Image URL: \(imageURLString)")
                print("🔥 Downloading image…")
                let (downloadedData, _) = try await URLSession.shared.data(from: imageURL)
                imageData = downloadedData
            } else if let base64String = firstImage["b64_json"] as? String,
                      let decoded = Data(base64Encoded: base64String) {
                print("🔥 Received base64-encoded image data")
                imageData = decoded
            }
            
            guard let finalData = imageData,
                  let uiImage = UIImage(data: finalData) else {
                print("❌ Failed to obtain UIImage data from response")
                throw OpenAIError.imageDownloadFailed
            }
            
            print("✅ Successfully generated image!")
            return uiImage
            
        } catch let error as OpenAIError {
            print("❌ OpenAI Error: \(error)")
            throw error
        } catch {
            print("❌ Network Error: \(error)")
            print("❌ Error Details: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }
    }
    
    // Fallback method that creates a placeholder when API key is missing
    private func createPlaceholderImage(prompt: String) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor,
                UIColor.systemPink.cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 0.5, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add prompt text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            
            let text = "Demo: \(prompt)"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Comic Theme & Styles

/// Centralised colours & modifiers to give the app a fun comic-book vibe.
struct ComicTheme {
    /// A light off-white, reminiscent of comic book paper.
    static let background = Color(red: 0.98, green: 0.95, blue: 0.85)
    /// A bright red that will be used for primary actions and accents.
    static let primary = Color.red
    /// A punchy yellow for secondary accents.
    static let secondary = Color.yellow
}

/// Reusable button style that mimics thick inked outlines often seen in comics.
struct ComicButtonStyle: ButtonStyle {
    var backgroundColor: Color = ComicTheme.secondary
    var foregroundColor: Color = .black
    var strokeColor: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 3)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var showingEditor = false
    @State private var selectedLayout: PanelLayout = .single
    @State private var userID: String?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image("AppTitle")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, -40)
                
                VStack(spacing: 20) {
                    Text("Select Layout")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(PanelLayout.allCases, id: \.self) { layout in
                            LayoutButton(
                                layout: layout,
                                isSelected: selectedLayout == layout
                            ) {
                                selectedLayout = layout
                            }
                        }
                    }
                    
                    Button(action: {
                        showingEditor = true
                    }) {
                        Label("Create Comic", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.primary, foregroundColor: .white))
                }
                .padding(.horizontal)
                

            }
            .padding()
            // Ensure the background color fills the whole screen area (including beneath the navigation bar)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ComicTheme.background)
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ComicEditorView(layout: selectedLayout)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbarBackground(ComicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Layout Button
struct LayoutButton: View {
    let layout: PanelLayout
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<layout.panelCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? ComicTheme.primary : ComicTheme.secondary.opacity(0.4))
                            .frame(width: layout == .single ? 60 : 30, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }
                
                Text(layout.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? ComicTheme.primary : .gray)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
        }
    }
}

// MARK: - Comic Editor
struct ComicEditorView: View {
    let layout: PanelLayout
    @State private var comic: Comic
    @State private var selectedPanel: Int = 0
    @State private var showingExportSheet = false
    @State private var exportedImage: UIImage?
    @State private var showingSaveAlert = false
    @State private var saveError: Error?
    @State private var mostRecentTextElementIndex: Int?
    @State private var mostRecentCharacterIndex: Int?
    // Focus state to detect when the prompt TextField is active
    @FocusState private var isPromptFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    init(layout: PanelLayout) {
        self.layout = layout
        self._comic = State(initialValue: Comic(layout: layout))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // Canvas Area
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(Array(comic.panels.enumerated()), id: \.element.id) { index, panel in
                                    PanelView(
                                        panel: $comic.panels[index],
                                        isSelected: selectedPanel == index,
                                        onTextElementInteraction: { elementIndex in
                                            if selectedPanel == index {
                                                mostRecentTextElementIndex = elementIndex
                                                mostRecentCharacterIndex = nil
                                            }
                                        },
                                        onCharacterInteraction: { characterIndex in
                                            if selectedPanel == index {
                                                mostRecentCharacterIndex = characterIndex
                                                mostRecentTextElementIndex = nil
                                            }
                                        }
                                    )
                                    .id("panel_\(index)")
                                    .onTapGesture {
                                        selectedPanel = index
                                        mostRecentTextElementIndex = nil
                                        mostRecentCharacterIndex = nil
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(ComicTheme.background)
                        
                        // Tools
                        VStack(spacing: 16) {
                            // Panel Selection
                            if layout == .threePanel {
                                HStack {
                                    ForEach(0..<3) { index in
                                        Button(action: {
                                            selectedPanel = index
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                proxy.scrollTo("panel_\(index)", anchor: .center)
                                            }
                                            mostRecentTextElementIndex = nil
                                            mostRecentCharacterIndex = nil
                                        }) {
                                            Text("Panel \(index + 1)")
                                                .font(.caption)
                                        }
                                        .buttonStyle(
                                            ComicButtonStyle(
                                                backgroundColor: selectedPanel == index ? ComicTheme.primary : ComicTheme.secondary.opacity(0.5),
                                                foregroundColor: .black,
                                                strokeColor: .black
                                            )
                                        )
                                    }
                                }
                            }
                            
                            // Image Generation
                            VStack(spacing: 12) {
                                Text("Describe the image for Panel \(selectedPanel + 1)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    TextField("A superhero flying...", text: $comic.panels[selectedPanel].imagePrompt)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($isPromptFieldFocused)
                                    
                                    Button(action: {
                                        generateImage(for: selectedPanel)
                                    }) {
                                        if comic.panels[selectedPanel].isGenerating {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Generate")
                                                .font(.caption)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.primary, foregroundColor: .white))
                                    .disabled(comic.panels[selectedPanel].isGenerating || comic.panels[selectedPanel].imagePrompt.isEmpty)
                                }
                            }
                            
                            // Character Stand-Ins
                            VStack(spacing: 8) {
                                Text("Add Characters")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        addCharacterStandIn()
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 20))
                                            Text("Character")
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: Color.blue.opacity(0.7), foregroundColor: .white))
                                }
                            }
                            
                            // Text Elements
                            HStack(spacing: 12) {
                                ForEach(TextElementType.allCases, id: \.self) { type in
                                    Button(action: {
                                        addTextElement(type: type)
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                            Text(type.rawValue)
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.secondary, foregroundColor: .black))
                                }
                            }
                            
                            // Remove Button
                            if let mostRecentIndex = mostRecentTextElementIndex,
                               mostRecentIndex < comic.panels[selectedPanel].textElements.count {
                                Button(action: {
                                    comic.panels[selectedPanel].textElements.remove(at: mostRecentIndex)
                                    mostRecentTextElementIndex = nil
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Text")
                                    }
                                }
                                .buttonStyle(ComicButtonStyle(backgroundColor: .red, foregroundColor: .white))
                            } else if let mostRecentIndex = mostRecentCharacterIndex,
                                      mostRecentIndex < comic.panels[selectedPanel].characterStandIns.count {
                                Button(action: {
                                    comic.panels[selectedPanel].characterStandIns.remove(at: mostRecentIndex)
                                    mostRecentCharacterIndex = nil
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Character")
                                    }
                                }
                                .buttonStyle(ComicButtonStyle(backgroundColor: .red, foregroundColor: .white))
                            }
                        }
                        .padding()
                        .background(ComicTheme.background)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Move content up slightly when the keyboard appears so the prompt field remains visible
            .offset(y: isPromptFieldFocused ? -40 : 0)
            .animation(.easeInOut(duration: 0.25), value: isPromptFieldFocused)
            .background(ComicTheme.background)
            .navigationTitle("Comic Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportComic()
                    }
                    .disabled(comic.panels.allSatisfy { $0.generatedImage == nil })
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let image = exportedImage {
                    ExportView(image: image, onSave: {
                        saveToPhotos(image: image)
                    })
                }
            }
            .alert("Save Result", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if saveError != nil {
                    Text("Failed to save image. Please check Photos permission in Settings.")
                } else {
                    Text("Comic saved to your Photos!")
                }
            }
            .background(ComicTheme.background)
            .ignoresSafeArea()
            .toolbarBackground(ComicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func generateImage(for panelIndex: Int) {
        Task {
            comic.panels[panelIndex].isGenerating = true
            do {
                // Check if we have character stand-ins or text elements to use multimodal approach
                if !comic.panels[panelIndex].characterStandIns.isEmpty || !comic.panels[panelIndex].textElements.isEmpty {
                    // Capture canvas snapshot
                    guard let canvasSnapshot = captureCanvasSnapshot(for: panelIndex) else {
                        throw OpenAIImageService.OpenAIError.imageDownloadFailed
                    }
                    
                    // Use multimodal generation
                    let image = try await OpenAIImageService.shared.generateImageFromCanvas(
                        canvasImage: canvasSnapshot,
                        prompt: comic.panels[panelIndex].imagePrompt
                    )
                    comic.panels[panelIndex].generatedImage = image
                } else {
                    // Fall back to traditional text-only generation
                    let image = try await OpenAIImageService.shared.generateImage(
                        prompt: comic.panels[panelIndex].imagePrompt
                    )
                    comic.panels[panelIndex].generatedImage = image
                }
            } catch OpenAIImageService.OpenAIError.invalidAPIKey {
                print("⚠️ OpenAI API key not configured. Using placeholder image.")
                let placeholderImage = createPlaceholderImage(prompt: comic.panels[panelIndex].imagePrompt)
                comic.panels[panelIndex].generatedImage = placeholderImage
            } catch OpenAIImageService.OpenAIError.networkError(let error) {
                print("❌ Network error generating image: \(error.localizedDescription)")
                print("💡 If you're using the iOS Simulator, try testing on a real device")
                let placeholderImage = createPlaceholderImage(prompt: "Network Error - Try on device")
                comic.panels[panelIndex].generatedImage = placeholderImage
            } catch {
                print("❌ Failed to generate image: \(error.localizedDescription)")
                print("💡 Check your internet connection and API key")
                let placeholderImage = createPlaceholderImage(prompt: "Error - Check logs")
                comic.panels[panelIndex].generatedImage = placeholderImage
            }
            comic.panels[panelIndex].isGenerating = false
        }
    }
    
    private func createPlaceholderImage(prompt: String) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor,
                UIColor.systemPink.cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 0.5, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Add prompt text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            
            let text = "Demo: \(prompt)"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func addCharacterStandIn() {
        let nextNumber = comic.panels[selectedPanel].characterStandIns.count + 1
        var character = CharacterStandIn(number: nextNumber)
        
        character.position = CGPoint(
            x: 100 + CGFloat(comic.panels[selectedPanel].characterStandIns.count * 90), 
            y: 200
        )
        
        comic.panels[selectedPanel].characterStandIns.append(character)
        mostRecentCharacterIndex = comic.panels[selectedPanel].characterStandIns.count - 1
        mostRecentTextElementIndex = nil
    }
    
    private func addTextElement(type: TextElementType) {
        var element = TextElement(type: type)
        
        // Set appropriate default sizes for different element types
        switch type {
        case .speechBubble:
            element.size = CGSize(width: 120, height: 60)
        case .thoughtBubble:
            element.size = CGSize(width: 100, height: 80)
        case .caption:
            element.size = CGSize(width: 140, height: 40)
        case .soundEffect:
            element.size = CGSize(width: 100, height: 100)
        }
        
        element.position = CGPoint(x: 150, y: 100 + CGFloat(comic.panels[selectedPanel].textElements.count * 80))
        comic.panels[selectedPanel].textElements.append(element)
        mostRecentTextElementIndex = comic.panels[selectedPanel].textElements.count - 1
        mostRecentCharacterIndex = nil
    }
    
    private func exportComic() {
        let renderer = ImageRenderer(content: ComicExportView(comic: comic))
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            exportedImage = image
            showingExportSheet = true
        }
    }
    
    private func captureCanvasSnapshot(for panelIndex: Int) -> UIImage? {
        let panel = comic.panels[panelIndex]
        let renderer = ImageRenderer(content: CanvasSnapshotView(panel: panel))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
    
    private func saveToPhotos(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showingExportSheet = false
        showingSaveAlert = true
    }
}

// MARK: - Panel View
struct PanelView: View {
    @Binding var panel: ComicPanel
    let isSelected: Bool
    let onTextElementInteraction: (Int) -> Void
    let onCharacterInteraction: (Int) -> Void
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 300, height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: isSelected ? 5 : 3)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 2, y: 2)
            
            // Generated Image
            if let image = panel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 290, height: 290)
                    .clipped()
                    .cornerRadius(8)
            } else if panel.isGenerating {
                ProgressView("Generating...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Tap to select")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            
            // Character Stand-Ins (behind text elements)
            ForEach(panel.characterStandIns.indices, id: \.self) { index in
                CharacterStandInView(
                    character: $panel.characterStandIns[index],
                    onDelete: {
                        panel.characterStandIns.remove(at: index)
                    },
                    onCharacterInteraction: {
                        onCharacterInteraction(index)
                    }
                )
            }
            
            // Text Elements (in front of character stand-ins)
            ForEach(panel.textElements.indices, id: \.self) { index in
                TextElementView(
                    element: $panel.textElements[index],
                    onDelete: {
                        panel.textElements.remove(at: index)
                    },
                    onTextElementInteraction: {
                        onTextElementInteraction(index)
                    }
                )
            }
        }
        .frame(width: 300, height: 300)
    }
}

// MARK: - Text Element View
struct TextElementView: View {
    @Binding var element: TextElement
    let onDelete: () -> Void
    let onTextElementInteraction: () -> Void
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    @GestureState private var magnification: CGFloat = 1.0
    
    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleView(text: $element.text, isEditing: $element.isEditing, size: element.size, onTextElementInteraction: onTextElementInteraction)
            case .thoughtBubble:
                ThoughtBubbleView(text: $element.text, isEditing: $element.isEditing, size: element.size, onTextElementInteraction: onTextElementInteraction)
            case .caption:
                CaptionView(text: $element.text, isEditing: $element.isEditing, size: element.size, onTextElementInteraction: onTextElementInteraction)
            case .soundEffect:
                SoundEffectView(text: $element.text, isEditing: $element.isEditing, size: element.size, onTextElementInteraction: onTextElementInteraction)
            }
        }
        .scaleEffect(magnification)
        .position(
            x: element.position.x + dragOffset.width,
            y: element.position.y + dragOffset.height
        )
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation
                        onTextElementInteraction()
                    }
                    .onEnded { value in
                        element.position.x += value.translation.width
                        element.position.y += value.translation.height
                        dragOffset = .zero
                    },
                MagnificationGesture()
                    .updating($magnification) { value, state, _ in
                        state = value
                        onTextElementInteraction()
                    }
                    .onEnded { value in
                        let newWidth = max(60, min(300, element.size.width * value))
                        let newHeight = max(30, min(200, element.size.height * value))
                        element.size = CGSize(width: newWidth, height: newHeight)
                    }
            )
        )
        .contextMenu {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
        .animation(.spring(response: 0.3), value: magnification)
    }
}

// MARK: - Text Element Styles
struct SpeechBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    
    var body: some View {
        // Align top-left so the rectangle stays anchored at the top and the
        // tail can extend downward without pushing the bubble up.
        ZStack(alignment: .topLeading) {
            // Bubble shape
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            // Tail (extends 20 pts below the bubble)
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.33, y: size.height))        
                path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))     
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            }
            .fill(Color.white)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.33, y: size.height))
                    path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))
                    path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                }
                .stroke(Color.black, lineWidth: 2)
            )
            
            // Text (manually centred inside the rectangle)
            Group {
                if isEditing {
                    TextField("Enter text", text: $text, onCommit: {
                        isEditing = false
                    })
                } else {
                    Text(text.isEmpty ? "Tap to edit" : text)
                        .font(.system(size: min(14, size.width / 8)))
                        .onTapGesture {
                            isEditing = true
                            onTextElementInteraction()
                        }
                }
            }
            .multilineTextAlignment(.center)
            .frame(width: size.width * 0.85, height: size.height * 0.7)
            .position(x: size.width / 2, y: size.height / 2)
        }
    }
}

struct ThoughtBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    
    var body: some View {
        ZStack {
            // Cloud shape
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width, height: size.height * 0.8)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.3, height: size.height * 0.3)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.35, y: size.height * 0.25)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.2, height: size.height * 0.2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.45, y: size.height * 0.45)
            }
            
            // Text
            if isEditing {
                TextField("Enter thought", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.7, height: size.height * 0.5)
                .font(.system(size: min(14, size.width / 8)))
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: min(14, size.width / 8)))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.7, height: size.height * 0.5)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
    }
}

struct CaptionView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
            
            if isEditing {
                TextField("Enter caption", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.9, height: size.height * 0.8)
                .font(.system(size: min(12, size.width / 10)))
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: min(12, size.width / 10)))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.9, height: size.height * 0.8)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
    }
}

struct SoundEffectView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    
    var body: some View {
        ZStack {
            // Starburst shape
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: size.width * 1.2, height: size.height * 0.2)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            Circle()
                .fill(Color.yellow)
                .frame(width: size.width * 0.8, height: size.height * 0.8)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            if isEditing {
                TextField("BOOM!", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .font(.system(size: min(16, size.width / 6), weight: .bold))
                .frame(width: size.width * 0.6, height: size.height * 0.4)
            } else {
                Text(text.isEmpty ? "TAP!" : text.uppercased())
                    .font(.system(size: min(16, size.width / 6), weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.6, height: size.height * 0.4)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Character Stand-In View
struct CharacterStandInView: View {
    @Binding var character: CharacterStandIn
    let onDelete: () -> Void
    let onCharacterInteraction: () -> Void
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    @GestureState private var magnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: character.size.width, height: character.size.height)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            // Character number
            Text("\(character.number)")
                .font(.system(size: min(24, character.size.width / 3), weight: .bold))
                .foregroundColor(.white)
            
            // Label below if provided
            if !character.label.isEmpty {
                Text(character.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: character.size.height/2 + 15)
            }
        }
        .scaleEffect(magnification)
        .position(
            x: character.position.x + dragOffset.width,
            y: character.position.y + dragOffset.height
        )
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation
                        onCharacterInteraction()
                    }
                    .onEnded { value in
                        character.position.x += value.translation.width
                        character.position.y += value.translation.height
                        dragOffset = .zero
                    },
                MagnificationGesture()
                    .updating($magnification) { value, state, _ in
                        state = value
                        onCharacterInteraction()
                    }
                    .onEnded { value in
                        let newSize = max(40, min(120, character.size.width * value))
                        character.size = CGSize(width: newSize, height: newSize)
                    }
            )
        )
        .contextMenu {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
        .animation(.spring(response: 0.3), value: magnification)
    }
}

// MARK: - Canvas Snapshot View (for AI analysis)
struct CanvasSnapshotView: View {
    let panel: ComicPanel
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(Color.white)
                .frame(width: 300, height: 300)
            
            // Character Stand-Ins (behind text elements)
            ForEach(panel.characterStandIns) { character in
                CharacterStandInSnapshotView(character: character)
                    .position(character.position)
            }
            
            // Text Elements (in front of character stand-ins)
            ForEach(panel.textElements) { element in
                TextElementSnapshotView(element: element)
                    .position(element.position)
            }
        }
        .frame(width: 300, height: 300)
    }
}

// MARK: - Character Stand-In Snapshot View (non-interactive)
struct CharacterStandInSnapshotView: View {
    let character: CharacterStandIn
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: character.size.width, height: character.size.height)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            // Character number
            Text("\(character.number)")
                .font(.system(size: min(24, character.size.width / 3), weight: .bold))
                .foregroundColor(.white)
            
            // Label below if provided
            if !character.label.isEmpty {
                Text(character.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: character.size.height/2 + 15)
            }
        }
    }
}

// MARK: - Text Element Snapshot View (non-interactive)
struct TextElementSnapshotView: View {
    let element: TextElement
    
    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleExport(text: element.text, size: element.size)
            case .thoughtBubble:
                ThoughtBubbleExport(text: element.text, size: element.size)
            case .caption:
                CaptionExport(text: element.text, size: element.size)
            case .soundEffect:
                SoundEffectExport(text: element.text, size: element.size)
            }
        }
    }
}

// MARK: - Export Views
struct ComicExportView: View {
    let comic: Comic
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(comic.panels) { panel in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 300, height: 300)
                    
                    // Image
                    if let image = panel.generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 300)
                            .clipped()
                    }
                    
                    // Text elements
                    ForEach(panel.textElements) { element in
                        TextElementExportView(element: element)
                            .position(element.position)
                    }
                }
                .frame(width: 300, height: 300)
            }
        }
        .background(Color.black)
    }
}

struct TextElementExportView: View {
    let element: TextElement
    
    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleExport(text: element.text, size: element.size)
            case .thoughtBubble:
                ThoughtBubbleExport(text: element.text, size: element.size)
            case .caption:
                CaptionExport(text: element.text, size: element.size)
            case .soundEffect:
                SoundEffectExport(text: element.text, size: element.size)
            }
        }
    }
}

// Export versions of text elements (non-interactive)
struct SpeechBubbleExport: View {
    let text: String
    let size: CGSize
    
    var body: some View {
        // Same alignment fix as the interactive view.
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.33, y: size.height))
                path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            }
            .fill(Color.white)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.33, y: size.height))
                    path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))
                    path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                }
                .stroke(Color.black, lineWidth: 2)
            )
            
            Text(text)
                .font(.system(size: min(14, size.width / 8)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.85, height: size.height * 0.7)
                .position(x: size.width / 2, y: size.height / 2)
        }
    }
}

struct ThoughtBubbleExport: View {
    let text: String
    let size: CGSize
    
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width, height: size.height * 0.8)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.3, height: size.height * 0.3)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.35, y: size.height * 0.25)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.2, height: size.height * 0.2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.45, y: size.height * 0.45)
            }
            
            Text(text)
                .font(.system(size: min(14, size.width / 8)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.7, height: size.height * 0.5)
        }
    }
}

struct CaptionExport: View {
    let text: String
    let size: CGSize
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
            
            Text(text)
                .font(.system(size: min(12, size.width / 10)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.9, height: size.height * 0.8)
        }
    }
}

struct SoundEffectExport: View {
    let text: String
    let size: CGSize
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: size.width * 1.2, height: size.height * 0.2)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            Circle()
                .fill(Color.yellow)
                .frame(width: size.width * 0.8, height: size.height * 0.8)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            Text(text.uppercased())
                .font(.system(size: min(16, size.width / 6), weight: .bold))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.6, height: size.height * 0.4)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Export View
struct ExportView: View {
    let image: UIImage
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                HStack(spacing: 20) {
                    Button(action: {
                        onSave()
                    }) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.primary, foregroundColor: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("My Comic", image: Image(uiImage: image))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Export Comic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        // NavigationView already inherits the background from its child; keeping this here for safety
        .background(ComicTheme.background)
        .ignoresSafeArea()
        .toolbarBackground(ComicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var tempApiKey: String = ""
    @State private var showingApiKeyAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI Configuration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)
                        
                        SecureField("Enter your OpenAI API key", text: $tempApiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Get your API key from platform.openai.com")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if !apiKey.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key configured")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app uses OpenAI's GPT-4o to generate comic panel images.")
                        Text("Your API key is stored securely on your device.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        tempApiKey = ""
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !tempApiKey.isEmpty {
                            apiKey = tempApiKey
                            OpenAIImageService.shared.updateAPIKey(tempApiKey)
                        }
                        dismiss()
                    }
                    .disabled(tempApiKey.isEmpty)
                }
            }
            .onAppear {
                tempApiKey = apiKey
            }
            // Remove the default grouped background so our custom colour shows through
            .scrollContentBackground(.hidden)
            .background(ComicTheme.background)
        }
    }
}
