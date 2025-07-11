# StoryPanels — AI Comic Maker

<p align="center">
  <img src="StoryPanels/Assets.xcassets/LaunchLogo.imageset/StoryPanels.png" alt="StoryPanels Logo" width="200">
</p>

An iOS application that democratizes comic creation by combining AI-generated artwork with intuitive text placement tools. Create professional-looking comic strips in minutes by describing what you want to see and adding your own dialogue and narration.

## 🎯 Key Features

- **AI-Powered Image Generation**: Uses OpenAI's GPT-4o to create comic-style images from text descriptions
- **Multiple Panel Layouts**: Support for 1-panel and 3-panel comic formats
- **Interactive Text Elements**: Add speech bubbles, thought bubbles, captions, and sound effects
- **Character Stand-ins**: Position placeholder characters that get replaced in AI generation
- **Style Themes**: Choose from Classic, Manga, Noir, and Sci-Fi art styles
- **Export & Share**: Save to Photos or share directly via iOS share sheet
- **No Artistic Skill Required**: Focus on storytelling while AI handles the artwork

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- OpenAI API key (for image generation)

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/StoryPanels.git
cd StoryPanels
```

2. Open `StoryPanels.xcodeproj` in Xcode

3. Build and run on iPhone 16 simulator or device:
```bash
xcodebuild -project StoryPanels.xcodeproj -scheme StoryPanels -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### OpenAI API Setup

1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open the app and go to Settings (gear icon)
3. Enter your API key in the configuration section
4. Start creating comics!

> **Note**: Without an API key, the app will generate placeholder images for testing purposes.

## 🎨 How to Use

### Creating Your First Comic

1. **Select Layout**: Choose between 1-panel or 3-panel format on the home screen
2. **Generate Images**: 
   - Tap a panel to select it
   - Enter a description (e.g., "superhero flying over city skyline")
   - Choose an art style theme
   - Tap "Generate" to create the image
3. **Add Text Elements**:
   - Use the toolbar to add speech bubbles, thought bubbles, captions, or sound effects
   - Drag elements to position them
   - Tap to edit text content
   - Pinch to resize elements
4. **Add Characters** (Optional):
   - Add character stand-ins to help AI understand positioning
   - These blue circles with numbers get replaced by actual characters in generation
5. **Export**: Tap "Export" to save or share your completed comic

### Multi-Modal Generation

StoryPanels supports an advanced workflow where you can:
1. Place character stand-ins and text elements first
2. Generate images that incorporate these elements
3. The AI analyzes your layout and creates images that respect character positioning and text placement

## 🛠 Architecture

### Key Components

- **ContentView.swift**: Main app interface and navigation
- **ComicEditorView**: Primary editing interface with canvas and tools
- **OpenAIImageService**: Handles API communication and image generation
- **PanelView**: Individual comic panel with interactive elements
- **TextElementView**: Draggable and resizable text components
- **CharacterStandInView**: Positioning helpers for character placement

### Data Models

- **Comic**: Top-level structure containing panels and theme
- **ComicPanel**: Individual panel with image, text elements, and characters
- **TextElement**: Speech bubbles, captions, etc. with position and content
- **CharacterStandIn**: Placeholder characters for AI generation
- **StyleTheme**: Art style definitions with prompt modifiers

## 🎨 Supported Text Elements

| Type | Description | Visual Style |
|------|-------------|--------------|
| Speech Bubble | Character dialogue | White bubble with tail |
| Thought Bubble | Internal monologue | Cloud-like shape |
| Caption | Narration text | Yellow rectangular box |
| Sound Effect | Action words | Starburst with bold text |

## 🎭 Art Style Themes

- **Classic**: Golden Age comic book style with bold lines
- **Manga**: Highly detailed Japanese manga style
- **Noir**: Black-and-white with dramatic shadows
- **Sci-Fi**: Futuristic style with glowing tech elements

## 📁 Project Structure

```
StoryPanels/
├── StoryPanels/
│   ├── StoryPanelsApp.swift       # App entry point with SwiftData setup
│   ├── ContentView.swift          # Main UI with all components
│   ├── Item.swift                 # SwiftData model (placeholder)
│   └── Assets.xcassets/          # App icons and images
├── StoryPanelsTests/             # Unit tests
├── StoryPanelsUITests/           # UI automation tests
├── Product Definition            # Detailed product requirements
├── CLAUDE.md                     # Development guidelines
└── README.md                     # This file
```

## 🚀 Building & Testing

### Build for Simulator
```bash
xcodebuild -project StoryPanels.xcodeproj -scheme StoryPanels -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Run Tests
```bash
xcodebuild test -project StoryPanels.xcodeproj -scheme StoryPanels -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 🔧 Configuration

### Environment Variables
- `OPENAI_API_KEY`: Set your OpenAI API key (alternative to in-app configuration)

### User Defaults
- `openai_api_key`: Stores the configured API key securely on device

## 🎯 Target Audience

- **Primary**: Creative individuals (16-35) who want to tell visual stories without drawing skills
- **Secondary**: Social media content creators and educators
- **Tertiary**: Professional content creators for rapid prototyping

## 🚧 Roadmap

### Current Features (MVP)
- ✅ 1 & 3 panel layouts
- ✅ AI image generation
- ✅ Four text element types
- ✅ Character positioning system
- ✅ Export to Photos
- ✅ Style theme selection

### Planned Features
- **v1.1**: Premium subscription with extended layouts and higher resolution
- **v1.2**: Custom image uploads and advanced editing tools
- **v2.0**: Cloud storage and social features

## 🛡 Privacy & Security

- API keys are stored locally on device using UserDefaults
- No user-generated content is stored on external servers
- All comic creation happens locally with direct API calls to OpenAI

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support or questions:
- Check the in-app FAQ and help sections
- Review the Product Definition document for detailed requirements
- Open an issue on GitHub for bugs or feature requests

## 🙏 Acknowledgments

- OpenAI for GPT-4o image generation capabilities
- The comic book community for inspiration and feedback
- Beta testers and early adopters

---

**Made with ❤️ for storytellers everywhere**