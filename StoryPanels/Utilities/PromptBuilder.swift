import Foundation

enum PromptBuilder {
    static func generationPrompt(basePrompt: String, theme: StyleTheme) -> String {
        let trimmed = basePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Comic panel, \(theme.promptModifier)"
        }
        return "\(trimmed). \(theme.promptModifier)"
    }

    static func layoutEditPrompt(basePrompt: String, theme: StyleTheme) -> String {
        let trimmed = basePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Create a cohesive comic panel scene." : trimmed
        return """
        Transform this comic panel layout into a professional comic book illustration. The numbered blue circles are placeholders that must be completely replaced with actual illustrated characters. Remove all blue circles and replace each numbered position with a fully drawn character that fits the scene. Remove any existing text bubbles and create new professional comic book style speech/thought bubbles with proper text. Add a detailed background scene. Use comic book art style with bold lines, vibrant colors, and dynamic composition. Scene description: \(base). \(theme.promptModifier)
        """
    }

    static func bakeTextPrompt(basePrompt: String, theme: StyleTheme) -> String {
        let trimmed = basePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Preserve the exact text and bubble placement from the provided image." : trimmed
        return """
        Re-illustrate this comic strip in a polished comic-book style. Keep the exact text content and bubble placement from the provided image, but render the bubbles and typography in a hand-drawn comic style. Ensure text is perfectly legible. \(base). \(theme.promptModifier)
        """
    }
}
