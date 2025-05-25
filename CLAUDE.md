# Claude Development Rules

## Build Commands
- Always build with iPhone 16 simulator target
- Use: `xcodebuild -project StoryPanels.xcodeproj -scheme StoryPanels -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build`