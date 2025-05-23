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
        
        let requestBody: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "auto"
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
                  let firstImage = dataArray.first,
                  let imageURLString = firstImage["url"] as? String,
                  let imageURL = URL(string: imageURLString) else {
                print("❌ Failed to parse image URL from response")
                throw OpenAIError.noImageURL
            }
            
            print("🔥 Image URL: \(imageURLString)")
            print("🔥 Downloading image...")
            
            // Download the generated image
            let (imageData, _) = try await URLSession.shared.data(from: imageURL)
            
            print("🔥 Downloaded \(imageData.count) bytes")
            
            guard let uiImage = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage from data")
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

// MARK: - Content View
struct ContentView: View {
    @State private var showingEditor = false
    @State private var selectedLayout: PanelLayout = .single
    @State private var userID: String?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("AI Comic Maker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
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
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                

            }
            .padding()
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
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: layout == .single ? 60 : 30, height: 40)
                    }
                }
                
                Text(layout.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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
                                        isSelected: selectedPanel == index
                                    )
                                    .id("panel_\(index)")
                                    .onTapGesture {
                                        selectedPanel = index
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color.gray.opacity(0.1))
                        
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
                                        }) {
                                            Text("Panel \(index + 1)")
                                                .font(.caption)
                                                .foregroundColor(selectedPanel == index ? .white : .blue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    selectedPanel == index ? Color.blue : Color.clear
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.blue, lineWidth: 1)
                                                )
                                        }
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
                                        }
                                    }
                                    .frame(width: 80)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .disabled(comic.panels[selectedPanel].isGenerating || comic.panels[selectedPanel].imagePrompt.isEmpty)
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
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                    }
                }
            }
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
        }
    }
    
    private func generateImage(for panelIndex: Int) {
        Task {
            comic.panels[panelIndex].isGenerating = true
            do {
                let image = try await OpenAIImageService.shared.generateImage(
                    prompt: comic.panels[panelIndex].imagePrompt
                )
                comic.panels[panelIndex].generatedImage = image
            } catch OpenAIImageService.OpenAIError.invalidAPIKey {
                print("⚠️ OpenAI API key not configured. Using placeholder image.")
                // Fallback to placeholder for demo purposes
                let placeholderImage = createPlaceholderImage(prompt: comic.panels[panelIndex].imagePrompt)
                comic.panels[panelIndex].generatedImage = placeholderImage
            } catch OpenAIImageService.OpenAIError.networkError(let error) {
                print("❌ Network error generating image: \(error.localizedDescription)")
                print("💡 If you're using the iOS Simulator, try testing on a real device")
                print("💡 The network errors you're seeing are common in the Simulator")
                // Could show user-facing error here
                let placeholderImage = createPlaceholderImage(prompt: "Network Error - Try on device")
                comic.panels[panelIndex].generatedImage = placeholderImage
            } catch {
                print("❌ Failed to generate image: \(error.localizedDescription)")
                print("💡 Check your internet connection and API key")
                // Could show user-facing error here
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
    
    private func addTextElement(type: TextElementType) {
        var element = TextElement(type: type)
        element.position = CGPoint(x: 150, y: 100 + CGFloat(comic.panels[selectedPanel].textElements.count * 80))
        comic.panels[selectedPanel].textElements.append(element)
    }
    
    private func exportComic() {
        let renderer = ImageRenderer(content: ComicExportView(comic: comic))
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            exportedImage = image
            showingExportSheet = true
        }
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
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 300, height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                )
            
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
            
            // Text Elements
            ForEach(panel.textElements.indices, id: \.self) { index in
                TextElementView(
                    element: $panel.textElements[index],
                    onDelete: {
                        panel.textElements.remove(at: index)
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
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    
    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleView(text: $element.text, isEditing: $element.isEditing)
            case .thoughtBubble:
                ThoughtBubbleView(text: $element.text, isEditing: $element.isEditing)
            case .caption:
                CaptionView(text: $element.text, isEditing: $element.isEditing)
            case .soundEffect:
                SoundEffectView(text: $element.text, isEditing: $element.isEditing)
            }
        }
        .position(
            x: element.position.x + dragOffset.width,
            y: element.position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    element.position.x += value.translation.width
                    element.position.y += value.translation.height
                    dragOffset = .zero
                }
        )
        .contextMenu {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
    }
}

// MARK: - Text Element Styles
struct SpeechBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    
    var body: some View {
        // Align top-left so the rectangle stays anchored at the top and the
        // tail can extend downward without pushing the bubble up.
        ZStack(alignment: .topLeading) {
            // Bubble shape
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 120, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            // Tail (extends 20 pts below the bubble)
            Path { path in
                path.move(to: CGPoint(x: 40, y: 60))        // bottom-centre of bubble
                path.addLine(to: CGPoint(x: 30, y: 80))     // tip of tail
                path.addLine(to: CGPoint(x: 60, y: 60))
            }
            .fill(Color.white)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 60))
                    path.addLine(to: CGPoint(x: 30, y: 80))
                    path.addLine(to: CGPoint(x: 60, y: 60))
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
                        .font(.system(size: 14))
                        .onTapGesture {
                            isEditing = true
                        }
                }
            }
            .multilineTextAlignment(.center)
            .frame(width: 100, height: 40)
            .position(x: 60, y: 30) // centre of the rectangle (120 × 60)
        }
    }
}

struct ThoughtBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            // Cloud shape
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 60)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -40, y: 20)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -50, y: 40)
            }
            
            // Text
            if isEditing {
                TextField("Enter thought", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 40)
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .frame(width: 80, height: 40)
                    .onTapGesture {
                        isEditing = true
                    }
            }
        }
    }
}

struct CaptionView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 140, height: 40)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
            
            if isEditing {
                TextField("Enter caption", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 30)
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .frame(width: 120, height: 30)
                    .onTapGesture {
                        isEditing = true
                    }
            }
        }
    }
}

struct SoundEffectView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            // Starburst shape
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 100, height: 20)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            Circle()
                .fill(Color.yellow)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            if isEditing {
                TextField("BOOM!", text: $text, onCommit: {
                    isEditing = false
                })
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 60, height: 30)
            } else {
                Text(text.isEmpty ? "TAP!" : text.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(width: 60, height: 30)
                    .onTapGesture {
                        isEditing = true
                    }
            }
        }
        .frame(width: 100, height: 100)
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
                SpeechBubbleExport(text: element.text)
            case .thoughtBubble:
                ThoughtBubbleExport(text: element.text)
            case .caption:
                CaptionExport(text: element.text)
            case .soundEffect:
                SoundEffectExport(text: element.text)
            }
        }
    }
}

// Export versions of text elements (non-interactive)
struct SpeechBubbleExport: View {
    let text: String
    
    var body: some View {
        // Same alignment fix as the interactive view.
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 120, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            Path { path in
                path.move(to: CGPoint(x: 40, y: 60))
                path.addLine(to: CGPoint(x: 30, y: 80))
                path.addLine(to: CGPoint(x: 60, y: 60))
            }
            .fill(Color.white)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 60))
                    path.addLine(to: CGPoint(x: 30, y: 80))
                    path.addLine(to: CGPoint(x: 60, y: 60))
                }
                .stroke(Color.black, lineWidth: 2)
            )
            
            Text(text)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 40)
                .position(x: 60, y: 30)
        }
    }
}

struct ThoughtBubbleExport: View {
    let text: String
    
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 60)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -40, y: 20)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -50, y: 40)
            }
            
            Text(text)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 40)
        }
    }
}

struct CaptionExport: View {
    let text: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 140, height: 40)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )
            
            Text(text)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 30)
        }
    }
}

struct SoundEffectExport: View {
    let text: String
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 100, height: 20)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            Circle()
                .fill(Color.yellow)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            Text(text.uppercased())
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(width: 60, height: 30)
        }
        .frame(width: 100, height: 100)
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
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
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
                        Text("This app uses OpenAI's DALL-E 3 to generate comic panel images.")
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
        }
    }
}
